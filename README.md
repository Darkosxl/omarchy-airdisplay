# AirDisplay for Omarchy

A bar widget that mirrors a whole screen to a TV over **Miracast**, or plays a video file on a TV over **DLNA**. Nothing gets installed on the TV. Samsung TVs, including The Frame, do both out of the box, and so do most other Miracast and DLNA displays.

Click the bar icon and the menu lists your screens:

```
󰍹  Monitor (LG ULTRAGEAR)   DP-2
󰌢  Laptop display           eDP-2
󰕧  Play video
```

Pick a screen, then a TV, and the whole screen shows up on it. The screen-share dialog never appears. The icon stays highlighted while something is on the TV, and its tooltip shows what is playing where. Open the menu again to stop.

## How it works

- **Mirror.** The widget runs [fluxcast](https://github.com/IlyaP358/fluxcast) as a Miracast (Wi-Fi Display) source over Wi-Fi Direct. The TV joins a direct Wi-Fi link to the laptop, so it doesn't need to be on the same network. Capture goes through the screen-share portal into GStreamer with x264 in zero-latency mode, which gives roughly 150 to 250 ms of delay.
- **Choosing the screen.** `airdisplay-picker` is a custom picker for xdg-desktop-portal-hyprland. When AirDisplay asks for a screen, the picker answers once with the screen you chose. Every other app still gets Omarchy's normal share picker.
- **Play video.** The file is transcoded with NVENC into an MPEG-TS stream, served over HTTP, and the TV is told to play it through DLNA. TV players buffer DLNA, so this suits videos, not mirroring.

## Requirements

- Omarchy, which provides Hyprland, NetworkManager and xdg-desktop-portal-hyprland.
- A Wi-Fi card with Wi-Fi Direct support. Most Intel cards have it. Check with `iw list | grep -A10 "Supported interface modes" | grep P2P`.
- fluxcast from the AUR, which pulls in GStreamer, dbus-next and wf-recorder.
- For **Play video** only: an NVIDIA GPU, since `ffmpeg` uses `h264_nvenc`.

## Install

1. **Add the plugin.**
   ```sh
   omarchy pkg aur add fluxcast
   omarchy plugin add https://github.com/Darkosxl/omarchy-airdisplay.git --enable
   ```
2. **Let the portal take the screen choice.** In `~/.config/hypr/xdph.conf`, set the picker to the plugin's script. Use the full path, because `~` is not expanded there.
   ```
   screencopy {
       custom_picker_binary = /home/YOU/.config/omarchy/plugins/darkosxl.airdisplay/airdisplay-picker
       allow_token_by_default = true
   }
   ```
   Then restart the portal:
   ```sh
   systemctl --user restart xdg-desktop-portal-hyprland
   ```
3. **Open the firewall for the TV.** The laptop hands the TV an address on 10.42.0.0/24 and the TV connects back on RTSP port 7236. With ufw, run:
   ```sh
   sudo ufw allow in proto udp from any port 68 to any port 67 comment airdisplay-miracast-dhcp
   sudo ufw allow in proto tcp from 10.42.0.0/24 to any port 7236 comment airdisplay-miracast
   ```
   For **Play video**, the TV fetches the stream from port 8099:
   ```sh
   sudo ufw allow from <TV IP> to any port 8099 proto tcp
   ```
4. **Optional: put the command on your PATH.** This lets you use it from a terminal or from an Omarchy menu entry.
   ```sh
   ln -s ~/.config/omarchy/plugins/darkosxl.airdisplay/airdisplay ~/.local/bin/airdisplay
   ```

The first time you mirror to a TV, the TV may ask you to allow the connection.

## Command line

```
airdisplay menu                     pick a screen (or a video), then a TV
airdisplay mirror [MONITOR] [TV]    mirror a monitor (default: focused monitor, last TV)
airdisplay play FILE [TV]           play a video file over DLNA
airdisplay stop                     stop whatever is on the TV
airdisplay tvs                      list Miracast TVs nearby
```

`TV` can be a TV's name, part of its name, or its Wi-Fi Direct MAC address as printed by `airdisplay tvs`.

## Update and remove

```sh
omarchy plugin update darkosxl.airdisplay
```

To remove it, undo the setup first, in this order:

1. **Restore the default share picker.** Set `custom_picker_binary = hyprland-preview-share-picker` in `~/.config/hypr/xdph.conf`, then run `systemctl --user restart xdg-desktop-portal-hyprland`. Skipping this breaks screen sharing in every app, because the portal would point at a deleted script.
2. **Remove the plugin and the optional PATH link.**
   ```sh
   omarchy plugin remove darkosxl.airdisplay
   rm -f ~/.local/bin/airdisplay
   ```
3. **Close the firewall ports.**
   ```sh
   sudo ufw delete allow in proto udp from any port 68 to any port 67 comment airdisplay-miracast-dhcp
   sudo ufw delete allow in proto tcp from 10.42.0.0/24 to any port 7236 comment airdisplay-miracast
   ```
4. **Remove fluxcast if nothing else uses it:** `omarchy pkg remove fluxcast`.

## Troubleshooting

- **The output of the last session** is in `$XDG_RUNTIME_DIR/airdisplay.log`.
- **"Couldn't mirror"** right after connecting usually means the firewall blocked the TV's DHCP request or its RTSP connection. Check step 3.
- **Stopping takes a few seconds**, because fluxcast closes the Wi-Fi Direct link cleanly first.

## License

MIT
