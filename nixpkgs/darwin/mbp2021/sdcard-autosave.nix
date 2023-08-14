{ pkgs, config, lib, ... }:
/*
  Example launchd agent to run a script when a volume is mounted:

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
   <key>Label</key>
   <string>com.example.sdcard</string>
   <key>ProgramArguments</key>
   <array>
      <string>/bin/sh</string>
      <string>PATH_TO_YOUR_SCRIPT</string>
   </array>
   <key>WatchPaths</key>
   <array>
      <string>/Volumes/YOUR_VOLUME_UUID</string>
   </array>
  </dict>
  </plist>
  ```

  Needs to be loaded via: `launchctl load ~/Library/LaunchAgents/org.nixos.voice-recorder-autosave.plist`
*/
{
  # environment.systemPackages = with pkgs; [ parallel ];

  # TODO re-write with Rust
  launchd.user.agents.voice-recorder-autosave = {
    script = ''
      #! /usr/bin/env nix-shell
      #! nix-shell -i bash -p coreutils gawk

      set -e

      shopt -s nullglob # skip loop if no files found

      DEST_DIR="$HOME/Downloads/voice-recorder"

      convert_to_m4a() {
        file="$1"
        if [ -f "$file" ]; then
          echo "Converting $file to .m4a"
          afconvert -f m4af -d aac "$file" "''${file%.*}.m4a"

          # Remove the original file
          rm "$file"
        fi
      }

      # of shape `DJI_06_20230810_165403.WAV`
      #               ^^ ^^^^^^^^ ^^^^^^
      #               1  2        3
      # 1: incrementing number
      # 2: date (YYYYMMDD)
      # 3: time (HHMMSS)
      copy_to_downloads() {
        local file=$1
        local volume=$(basename $2)
        # Extract the date from the file name
        DATE=$(echo $(basename $file) | awk -F_ '{print substr($3, 1, 8)}')
        YEAR=''${DATE:0:4}
        MONTH=''${DATE:4:2}
        DAY=''${DATE:6:2}

        # Construct the destination directory
        TARGET_DIR="$DEST_DIR/$volume/$YEAR-$MONTH-$DAY"

        # Create the destination directory if it doesn't exist
        mkdir -p "$TARGET_DIR"

        # Copy the file to the destination directory
        cp "$file" "$TARGET_DIR"

        echo "$TARGET_DIR/$file"
      }

      for volume in /Volumes/DJIMIC*; do
        new_recordings_found=false
        
        for dir in $volume/DJI_Audio_*; do
          if [ -d "$dir" ]; then
            # Your desired actions here. For demonstration, we'll just echo a message.
            echo $(date)
            echo "Running voice-recorder-autosave ($0) for $dir"

            files=($dir/*.WAV)
    
            if [ ''${#files[@]} -eq 0 ]; then
              echo "No files found in $dir"
              continue
            fi

            new_recordings_found=true

            pushd $dir
            ls -lh .

            for file in *.WAV; do
              copied_file=$(copy_to_downloads $file $volume)
              echo "Copied $file to $copied_file"
              convert_to_m4a $copied_file &
            done

            wait

            rm -rf *.WAV

            popd

          fi
        done

        # Unmount the volume
        diskutil unmount $volume
        if [ "$new_recordings_found" = true ]; then
          osascript -e "display notification \"Recordings saved to $DEST_DIR.\nPlease unplug microphone.\" with title \"Voice Recorder Autosave\""
        else
          osascript -e "display notification \"No new recordings found on $volume.\nPlease unplug microphone.\" with title \"Voice Recorder Autosave\""
        fi
          
      done

    '';

    serviceConfig = {
      WatchPaths = [ "/Volumes" ];
      StandardOutPath = "/tmp/voice-recorder-autosave.out.log";
      StandardErrorPath = "/tmp/voice-recorder-autosave.err.log";
    };
  };
}
