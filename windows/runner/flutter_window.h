#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The hit test code for the point |lparam| carries (screen coordinates),
  // as Windows wants it from WM_NCHITTEST: HTMINBUTTON, HTMAXBUTTON or
  // HTCLOSE over the buttons the Flutter side reported, and 0 over
  // everything else — the drag area, the resize borders and the client
  // area keep whatever the default handling gives them.
  LRESULT CaptionButtonAt(HWND window, LPARAM lparam) const;

  // Runs |button|'s command. The three are the ones the app's own title-bar
  // buttons end up sending: `window_manager` posts SC_MINIMIZE, SC_MAXIMIZE/
  // SC_RESTORE and — for the close button — SC_CLOSE as well, so the
  // unsaved-edits guard sees a click here exactly as it sees that one.
  void ActivateCaptionButton(HWND window, LRESULT button) const;

  // Takes the buttons' rectangles, in physical pixels from the window's
  // client origin.
  void SetCaptionButtons(const flutter::EncodableMap& buttons);

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // The channel the Flutter title bar reports those rectangles on.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      caption_channel_;

  // Where the title bar drew its minimize, maximize and close buttons (#169),
  // in physical pixels from the client origin. All three are answered, not
  // just the maximize one: the bar draws three buttons, so the hit test
  // reports three — the maximize one is what Windows asks about on hover,
  // and a click on any of them lands here.
  //
  // Nothing until the Flutter side has reported: the bar is drawn there, and
  // the runner cannot work the rectangles out for itself without copying the
  // bar's layout into a constant that the first change to the bar — the tabs
  // (#23), another button size, another scale factor — turns into a lie.
  std::optional<RECT> minimize_button_;
  std::optional<RECT> maximize_button_;
  std::optional<RECT> close_button_;

  // The caption button the mouse went down on, 0 when it went down anywhere
  // else: the release is what acts, and only over the button it started on.
  LRESULT pressed_caption_button_ = 0;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
