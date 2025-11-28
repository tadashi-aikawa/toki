import { to$, ToEvent } from "karabiner.ts";

export function toDynamicPaste(command: string): ToEvent {
  return to$(`  
    output=$(${command})  

    osascript <<EOF  
      set prev to the clipboard  
      set the clipboard to "$output"  
      tell application "System Events"  
        keystroke "v" using command down  
        delay 0.1
      end tell  
      set the clipboard to prev  
EOF 
  `);
}
