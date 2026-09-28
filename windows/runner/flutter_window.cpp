#include "flutter_window.h"

#include <cmath>
#include <optional>
#include <shellapi.h>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

namespace {

// Where the Flutter title bar reports its caption buttons, and how (#169):
// the `niman/window` channel, one `setCaptionButtons` call per layout the
// bar changes.
constexpr char kCaptionChannelName[] = "niman/window";
constexpr char kSetCaptionButtonsMethod[] = "setCaptionButtons";

// The three buttons in that call, each a rectangle in physical pixels from
// the window's client origin: {"left": .., "top": .., "right": ..,
// "bottom": ..}.
constexpr char kMinimizeKey[] = "minimize";
constexpr char kMaximizeKey[] = "maximize";
constexpr char kCloseKey[] = "close";
constexpr char kLeftKey[] = "left";
constexpr char kTopKey[] = "top";
constexpr char kRightKey[] = "right";
constexpr char kBottomKey[] = "bottom";

// Reads |value| as a pixel coordinate. The Flutter standard codec hands
// whole numbers over as ints and fractions as doubles, and which of the two
// arrives is not worth a bet on: the bar reports whole pixels, but a
// half-pixel layout or an older client would send the other.
bool ReadPixel(const flutter::EncodableValue& value, LONG* pixel) {
  if (const double* as_double = std::get_if<double>(&value)) {
    *pixel = static_cast<LONG>(std::lround(*as_double));
    return true;
  }
  if (std::holds_alternative<int32_t>(value) ||
      std::holds_alternative<int64_t>(value)) {
    *pixel = static_cast<LONG>(value.LongValue());
    return true;
  }
  return false;
}

// Reads one button's rectangle; false when a side of it is missing or is
// not a number.
bool ReadBounds(const flutter::EncodableMap& button, RECT* bounds) {
  const auto left = button.find(flutter::EncodableValue(kLeftKey));
  const auto top = button.find(flutter::EncodableValue(kTopKey));
  const auto right = button.find(flutter::EncodableValue(kRightKey));
  const auto bottom = button.find(flutter::EncodableValue(kBottomKey));
  if (left == button.end() || top == button.end() || right == button.end() ||
      bottom == button.end()) {
    return false;
  }
  RECT read = {};
  if (!ReadPixel(left->second, &read.left) ||
      !ReadPixel(top->second, &read.top) ||
      !ReadPixel(right->second, &read.right) ||
      !ReadPixel(bottom->second, &read.bottom)) {
    return false;
  }
  *bounds = read;
  return true;
}

// Reads the button named |key| out of a report; false when it is not there
// or is not a rectangle at all.
bool ReadButton(const flutter::EncodableMap& buttons, const char* key,
                RECT* bounds) {
  const auto entry = buttons.find(flutter::EncodableValue(key));
  if (entry == buttons.end()) {
    return false;
  }
  const flutter::EncodableMap* button =
      std::get_if<flutter::EncodableMap>(&entry->second);
  if (button == nullptr) {
    return false;
  }
  return ReadBounds(*button, bounds);
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Files and folders dropped on the window (#224): the paths Win32 hands
  // this window are passed on to Dart over niman/drop.
  drop_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "niman/drop",
          &flutter::StandardMethodCodec::GetInstance());
  DragAcceptFiles(GetHandle(), TRUE);

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // The bar the app draws is where its caption buttons are, and the hit test
  // in MessageHandler has to say so: they arrive here, one report per layout
  // the bar changes (#169).
  caption_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), kCaptionChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  caption_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != kSetCaptionButtonsMethod) {
          result->NotImplemented();
          return;
        }
        const flutter::EncodableMap* buttons =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (buttons == nullptr) {
          result->Error("bad-arguments",
                        "the caption buttons arrive as a map of rectangles");
          return;
        }
        SetCaptionButtons(*buttons);
        result->Success();
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (caption_channel_) {
    // The handler points back here, so it goes before the controller does.
    caption_channel_->SetMethodCallHandler(nullptr);
    caption_channel_ = nullptr;
  }
  if (flutter_controller_) {
    // The drop target goes with the engine it talks through.
    DragAcceptFiles(GetHandle(), FALSE);
    drop_channel_ = nullptr;
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

// A drop on the window: the paths Win32 names are handed to Dart, which
// opens or imports each one the way the rest of the app does (#224).
//
// The classic Win32 route, not an OLE IDropTarget on the view: this half
// reports the drop and nothing else. A drag that is over the window says
// nothing until it lands, so Windows drops land without the frame Linux
// draws while a drag is over it.
void FlutterWindow::SendDrop(WPARAM wparam) {
  HDROP drop = reinterpret_cast<HDROP>(wparam);
  const UINT count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
  flutter::EncodableList paths;
  for (UINT i = 0; i < count; ++i) {
    const UINT length = DragQueryFileW(drop, i, nullptr, 0);
    if (length == 0) {
      continue;
    }
    // The length is the path without its terminator; the buffer takes both.
    std::wstring wide(static_cast<size_t>(length) + 1, L'\0');
    DragQueryFileW(drop, i, wide.data(), length + 1);
    paths.push_back(flutter::EncodableValue(Utf8FromUtf16(wide.c_str())));
  }
  DragFinish(drop);

  if (drop_channel_) {
    drop_channel_->InvokeMethod(
        "drop", std::make_unique<flutter::EncodableValue>(paths));
  }
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;

    // The app's own caption buttons (#169). Windows offers the Snap Layouts
    // flyout only to a window that answers HTMAXBUTTON over its maximize
    // button, and takes a click on any of the three from the same answer, so
    // all three follow the bar Flutter drew instead of a caption the app is
    // only painting over. Everything else falls through to the default
    // handling below, which is where dragging and the resize borders come
    // from.
    case WM_NCHITTEST: {
      const LRESULT button = CaptionButtonAt(hwnd, lparam);
      if (button != 0) {
        return button;
      }
      break;
    }

    // A press on one of them is the runner's to finish. Left to the default
    // handling, Windows would act on it itself — and paint its own pressed
    // caption button over the bar while it did, which is not the button the
    // user sees. A double click's second press arrives as the second case
    // rather than as another first one, and is swallowed the same way: the
    // releases are what act, one per click, so a double click does not fire
    // three times.
    case WM_NCLBUTTONDOWN:
    case WM_NCLBUTTONDBLCLK: {
      const LRESULT button = CaptionButtonAt(hwnd, lparam);
      pressed_caption_button_ = button;
      if (button != 0) {
        return 0;
      }
      break;
    }

    case WM_NCLBUTTONUP: {
      // The release acts, and only over the button the press landed on: a
      // press that wandered off is not a click. A release over a button no
      // press was seen for still acts — it is under the cursor, and a
      // caption button that does nothing is the worse failure of the two.
      const LRESULT pressed = pressed_caption_button_;
      const LRESULT button = CaptionButtonAt(hwnd, lparam);
      pressed_caption_button_ = 0;
      if (button != 0 && (pressed == 0 || pressed == button)) {
        ActivateCaptionButton(hwnd, button);
        return 0;
      }
      break;
    }

    case WM_CANCELMODE:
      pressed_caption_button_ = 0;
      break;
    case WM_DROPFILES:
      SendDrop(wparam);
      // The drop is taken: nothing below it has anything to do with it.
      return 0;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

LRESULT FlutterWindow::CaptionButtonAt(HWND window, LPARAM lparam) const {
  if (!minimize_button_ || !maximize_button_ || !close_button_) {
    // Nothing reported yet, or the last report did not hold three
    // rectangles: the window answers the way it did before any of this.
    return 0;
  }

  // WM_NCHITTEST carries the cursor in screen coordinates, and the reported
  // rectangles are in the window's client space.
  const POINTS cursor = MAKEPOINTS(lparam);
  POINT point = {cursor.x, cursor.y};
  if (!::ScreenToClient(window, &point)) {
    return 0;
  }

  // Maximize first: it is the one Windows asks about for Snap Layouts. The
  // three do not overlap.
  if (::PtInRect(&*maximize_button_, point)) {
    return HTMAXBUTTON;
  }
  if (::PtInRect(&*minimize_button_, point)) {
    return HTMINBUTTON;
  }
  if (::PtInRect(&*close_button_, point)) {
    return HTCLOSE;
  }
  return 0;
}

void FlutterWindow::ActivateCaptionButton(HWND window, LRESULT button) const {
  switch (button) {
    case HTMINBUTTON:
      ::PostMessage(window, WM_SYSCOMMAND, SC_MINIMIZE, 0);
      break;
    case HTMAXBUTTON:
      ::PostMessage(window, WM_SYSCOMMAND,
                    ::IsZoomed(window) ? SC_RESTORE : SC_MAXIMIZE, 0);
      break;
    case HTCLOSE:
      // Goes through the close request like every other close does, so the
      // unsaved-edits guard gets its say.
      ::PostMessage(window, WM_SYSCOMMAND, SC_CLOSE, 0);
      break;
    default:
      break;
  }
}

void FlutterWindow::SetCaptionButtons(const flutter::EncodableMap& buttons) {
  RECT minimize = {};
  RECT maximize = {};
  RECT close = {};
  if (!ReadButton(buttons, kMinimizeKey, &minimize) ||
      !ReadButton(buttons, kMaximizeKey, &maximize) ||
      !ReadButton(buttons, kCloseKey, &close)) {
    // Half a report is not worth answering from: a rectangle left over from
    // an earlier layout is worse than no hit test at all, since it would
    // take clicks meant for the bar and the window's own edges. All three
    // go, and the next report puts them back.
    minimize_button_.reset();
    maximize_button_.reset();
    close_button_.reset();
    return;
  }
  minimize_button_ = minimize;
  maximize_button_ = maximize;
  close_button_ = close;
}
