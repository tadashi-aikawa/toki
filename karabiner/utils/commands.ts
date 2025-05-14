import { to$, ToEvent } from "https://deno.land/x/karabinerts@1.31.0/deno.ts";

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
