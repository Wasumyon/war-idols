Image files for the visual novel live here.

NAME CONVENTION
  A directive `@ img leg_pool` loads, in order:
      vn/img/leg_pool.png
      vn/img/leg_pool.webp
      vn/img/leg_pool.jpg
  So drop a file named after the image and use that name in the script.
  A full path also works: `@ img res://vn/img/whatever.png`.

BUILT-IN NAMES (no file needed)
  none / off    clears the illustration
  black         flat black backdrop
  white         flat white backdrop

NEEDED (from the scripts - the "# ART:" note beside each `@ img` is the brief)
  leg_pool    00_prologue   severed leg in power armour, pool of blood, yellow-green soil, a short distance away
  arm_crawl   00_prologue   a gauntleted arm dragging across the dirt toward the leg
  grab_leg    00_prologue   a hand closing on the severed leg
  stomp       00_prologue   a taloned heel stomping down on the arm

  Still missing: the glitch-reveal image (the figure he sees in the camera feed).
  Add a `# ART:` note and an `@ img <id>` on that beat when it exists.

A missing file does not crash - it logs a warning and shows the plain backdrop.

SUPPORTED FORMATS
  .png (recommended), .webp, .jpg
