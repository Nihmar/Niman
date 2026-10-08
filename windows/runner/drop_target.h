#ifndef RUNNER_DROP_TARGET_H_
#define RUNNER_DROP_TARGET_H_

#include <flutter/encodable_value.h>
#include <ole2.h>
#include <windows.h>

#include <functional>
#include <string>

// The window's OLE drop target (#224, #531).
//
// It replaces DragAcceptFiles/WM_DROPFILES, which only ever saw files: a
// link dragged from a browser arrives as a URL, never as a path, and only
// OLE hands it over. Files still go to Dart as paths ("drop"), a link as
// its address ("dropLinks"), and a drag over the window is reported as it
// comes in ("dragEntered", saying whether it is a link) and goes out
// ("dragExited"), so the frame Linux draws is drawn here too.
class DropTarget : public IDropTarget {
 public:
  // How the target talks to Dart: a method of niman/drop and its argument.
  using Send =
      std::function<void(const std::string& method, flutter::EncodableValue)>;

  explicit DropTarget(Send send);

  // IUnknown:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid,
                                           void** object) override;
  ULONG STDMETHODCALLTYPE AddRef() override;
  ULONG STDMETHODCALLTYPE Release() override;

  // IDropTarget:
  HRESULT STDMETHODCALLTYPE DragEnter(IDataObject* data, DWORD key_state,
                                      POINTL point, DWORD* effect) override;
  HRESULT STDMETHODCALLTYPE DragOver(DWORD key_state, POINTL point,
                                     DWORD* effect) override;
  HRESULT STDMETHODCALLTYPE DragLeave() override;
  HRESULT STDMETHODCALLTYPE Drop(IDataObject* data, DWORD key_state,
                                 POINTL point, DWORD* effect) override;

 private:
  virtual ~DropTarget() = default;

  // What the drag over the window carries.
  enum class Kind { kNone, kFiles, kLink };
  static Kind KindOf(IDataObject* data);

  // The paths of a file drop, the address of a link drop.
  static flutter::EncodableList PathsOf(IDataObject* data);
  static std::string LinkOf(IDataObject* data);

  LONG references_ = 1;
  Send send_;
  Kind kind_ = Kind::kNone;
};

#endif  // RUNNER_DROP_TARGET_H_
