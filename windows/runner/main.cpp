#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>    // ← ADD: needed for std::wstring

#include "flutter_window.h"
#include "utils.h"

// ── Deep link protocol registration ──────────────────────────────────────────
// Registers soundclone:// as a custom URL protocol handler in the Windows
// registry under HKEY_CURRENT_USER (no admin rights needed).
// This runs every launch to ensure the registration stays current even
// after the app is moved or updated.
static void RegisterDeepLinkProtocol() {
  // Get the full path to this executable.
  wchar_t exePath[MAX_PATH];
  GetModuleFileNameW(nullptr, exePath, MAX_PATH);

  // Build the shell open command: "C:\path\to\app.exe" "%1"
  // %1 is replaced by Windows with the full deep link URL at runtime.
  std::wstring cmd =
      std::wstring(L"\"") + exePath + L"\" \"%1\"";

  // ── Register the protocol root key ───────────────────────────────────────
  // HKEY_CURRENT_USER\Software\Classes\soundclone
  HKEY hKey;
  if (RegCreateKeyExW(
        HKEY_CURRENT_USER,
        L"Software\\Classes\\soundclone",
        0, nullptr, 0, KEY_WRITE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {

    // Default value — human-readable protocol description.
    const wchar_t* description = L"URL:soundclone Protocol";
    RegSetValueExW(hKey, L"", 0, REG_SZ,
        reinterpret_cast<const BYTE*>(description),
        static_cast<DWORD>((wcslen(description) + 1) * sizeof(wchar_t)));

    // URL Protocol marker — empty string value, must exist for Windows
    // to treat this key as a URL protocol handler.
    RegSetValueExW(hKey, L"URL Protocol", 0, REG_SZ,
        reinterpret_cast<const BYTE*>(L""),
        static_cast<DWORD>(sizeof(wchar_t)));

    RegCloseKey(hKey);
  }

  // ── Register the open command ─────────────────────────────────────────────
  // HKEY_CURRENT_USER\Software\Classes\soundclone\shell\open\command
  HKEY hCmdKey;
  if (RegCreateKeyExW(
        HKEY_CURRENT_USER,
        L"Software\\Classes\\soundclone\\shell\\open\\command",
        0, nullptr, 0, KEY_WRITE, nullptr, &hCmdKey, nullptr) == ERROR_SUCCESS) {

    RegSetValueExW(hCmdKey, L"", 0, REG_SZ,
        reinterpret_cast<const BYTE*>(cmd.c_str()),
        static_cast<DWORD>((cmd.size() + 1) * sizeof(wchar_t)));

    RegCloseKey(hCmdKey);
  }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Register soundclone:// protocol handler in the Windows registry.
  // Must run after COM init, before the Flutter window is created.
  RegisterDeepLinkProtocol();                                        // ← ADD

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"my_app", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}