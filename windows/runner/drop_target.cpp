#include "drop_target.h"

#include <shellapi.h>

#include <cwchar>
#include <utility>

#include "utils.h"

namespace {

// The clipboard format a browser puts a dragged link's address in.
CLIPFORMAT LinkFormat() {
  static const CLIPFORMAT format = static_cast<CLIPFORMAT>(
      RegisterClipboardFormatW(L"UniformResourceLocatorW"));
  return format;
}

FORMATETC FormatOf(CLIPFORMAT format) {
  FORMATETC etc = {};
  etc.cfFormat = format;
  etc.dwAspect = DVASPECT_CONTENT;
  etc.lindex = -1;
  etc.tymed = TYMED_HGLOBAL;
  return etc;
}

bool Offers(IDataObject* data, CLIPFORMAT format) {
  FORMATETC etc = FormatOf(format);
  return data != nullptr && data->QueryGetData(&etc) == S_OK;
}

}  // namespace

DropTarget::DropTarget(Send send) : send_(std::move(send)) {}

HRESULT DropTarget::QueryInterface(REFIID riid, void** object) {
  if (object == nullptr) {
    return E_POINTER;
  }
  if (riid == IID_IUnknown || riid == IID_IDropTarget) {
    *object = static_cast<IDropTarget*>(this);
    AddRef();
    return S_OK;
  }
  *object = nullptr;
  return E_NOINTERFACE;
}

ULONG DropTarget::AddRef() { return InterlockedIncrement(&references_); }

ULONG DropTarget::Release() {
  const ULONG count = InterlockedDecrement(&references_);
  if (count == 0) {
    delete this;
  }
  return count;
}

DropTarget::Kind DropTarget::KindOf(IDataObject* data) {
  // Files first: a file dragged from a browser's download list offers both,
  // and the file is what it is.
  if (Offers(data, CF_HDROP)) {
    return Kind::kFiles;
  }
  if (Offers(data, LinkFormat())) {
    return Kind::kLink;
  }
  return Kind::kNone;
}

HRESULT DropTarget::DragEnter(IDataObject* data, DWORD /*key_state*/,
                              POINTL /*point*/, DWORD* effect) {
  kind_ = KindOf(data);
  if (kind_ == Kind::kNone) {
    *effect = DROPEFFECT_NONE;
    return S_OK;
  }
  flutter::EncodableMap args;
  args[flutter::EncodableValue("link")] =
      flutter::EncodableValue(kind_ == Kind::kLink);
  send_("dragEntered", flutter::EncodableValue(args));
  *effect = kind_ == Kind::kLink ? DROPEFFECT_LINK : DROPEFFECT_COPY;
  return S_OK;
}

HRESULT DropTarget::DragOver(DWORD /*key_state*/, POINTL /*point*/,
                             DWORD* effect) {
  *effect = kind_ == Kind::kNone   ? DROPEFFECT_NONE
            : kind_ == Kind::kLink ? DROPEFFECT_LINK
                                   : DROPEFFECT_COPY;
  return S_OK;
}

HRESULT DropTarget::DragLeave() {
  if (kind_ != Kind::kNone) {
    send_("dragExited", flutter::EncodableValue());
  }
  kind_ = Kind::kNone;
  return S_OK;
}

HRESULT DropTarget::Drop(IDataObject* data, DWORD /*key_state*/,
                         POINTL /*point*/, DWORD* effect) {
  const Kind kind = KindOf(data);
  kind_ = Kind::kNone;
  if (kind == Kind::kFiles) {
    send_("drop", flutter::EncodableValue(PathsOf(data)));
    *effect = DROPEFFECT_COPY;
    return S_OK;
  }
  if (kind == Kind::kLink) {
    const std::string link = LinkOf(data);
    if (!link.empty()) {
      flutter::EncodableList links;
      links.push_back(flutter::EncodableValue(link));
      send_("dropLinks", flutter::EncodableValue(links));
      *effect = DROPEFFECT_LINK;
      return S_OK;
    }
  }
  // Nothing openable: the frame goes, and Dart says nothing came.
  send_("drop", flutter::EncodableValue(flutter::EncodableList()));
  *effect = DROPEFFECT_NONE;
  return S_OK;
}

flutter::EncodableList DropTarget::PathsOf(IDataObject* data) {
  flutter::EncodableList paths;
  FORMATETC etc = FormatOf(CF_HDROP);
  STGMEDIUM medium = {};
  if (data->GetData(&etc, &medium) != S_OK) {
    return paths;
  }
  HDROP drop = static_cast<HDROP>(GlobalLock(medium.hGlobal));
  if (drop != nullptr) {
    const UINT count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
    for (UINT i = 0; i < count; ++i) {
      const UINT length = DragQueryFileW(drop, i, nullptr, 0);
      if (length == 0) {
        continue;
      }
      // The length is the path without its terminator; the buffer takes
      // both.
      std::wstring wide(static_cast<size_t>(length) + 1, L'\0');
      DragQueryFileW(drop, i, wide.data(), length + 1);
      paths.push_back(flutter::EncodableValue(Utf8FromUtf16(wide.c_str())));
    }
    GlobalUnlock(medium.hGlobal);
  }
  ReleaseStgMedium(&medium);
  return paths;
}

std::string DropTarget::LinkOf(IDataObject* data) {
  FORMATETC etc = FormatOf(LinkFormat());
  STGMEDIUM medium = {};
  if (data->GetData(&etc, &medium) != S_OK) {
    return std::string();
  }
  std::string link;
  const wchar_t* wide = static_cast<const wchar_t*>(GlobalLock(medium.hGlobal));
  if (wide != nullptr) {
    // The block holds the address and its terminator; it is never trusted
    // to be longer than it says it is.
    const SIZE_T size = GlobalSize(medium.hGlobal) / sizeof(wchar_t);
    const std::wstring address(wide, wcsnlen(wide, size));
    link = Utf8FromUtf16(address.c_str());
    GlobalUnlock(medium.hGlobal);
  }
  ReleaseStgMedium(&medium);
  return link;
}
