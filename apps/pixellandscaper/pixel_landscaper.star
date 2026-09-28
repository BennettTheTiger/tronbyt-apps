"""
Applet: Pixel Landscaper
Summary: Tend to your pixels
Description: Shows an animation of a landcaper for the season.
Author: Bennett Schoonerman
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("animation.star", "animation")

# --- 1. LOAD ASSETS ---
# Tractor Left Frames
load("images/lawntractor/left/frame_000.png", tractor_left_f1 = "file")
load("images/lawntractor/left/frame_001.png", tractor_left_f2 = "file")
load("images/lawntractor/left/frame_002.png", tractor_left_f3 = "file")
load("images/lawntractor/left/frame_003.png", tractor_left_f4 = "file")
load("images/lawntractor/left/frame_004.png", tractor_left_f5 = "file")
load("images/lawntractor/left/frame_005.png", tractor_left_f6 = "file")
load("images/lawntractor/left/frame_006.png", tractor_left_f7 = "file")
load("images/lawntractor/left/frame_007.png", tractor_left_f8 = "file")

# Tractor Right Frames
load("images/lawntractor/right/frame_000.png", tractor_right_f1 = "file")
load("images/lawntractor/right/frame_001.png", tractor_right_f2 = "file")
load("images/lawntractor/right/frame_002.png", tractor_right_f3 = "file")
load("images/lawntractor/right/frame_003.png", tractor_right_f4 = "file")
load("images/lawntractor/right/frame_004.png", tractor_right_f5 = "file")
load("images/lawntractor/right/frame_005.png", tractor_right_f6 = "file")
load("images/lawntractor/right/frame_006.png", tractor_right_f7 = "file")
load("images/lawntractor/right/frame_007.png", tractor_right_f8 = "file")

# --- 2. GROUP ASSETS INTO A DICTIONARY ---
# This bypasses the string concatenation problem entirely!
TRACTOR_FRAMES = {
    "left": [
        tractor_left_f1, tractor_left_f2, tractor_left_f3, tractor_left_f4,
        tractor_left_f5, tractor_left_f6, tractor_left_f7, tractor_left_f8
    ],
    "right": [
        tractor_right_f1, tractor_right_f2, tractor_right_f3, tractor_right_f4,
        tractor_right_f5, tractor_right_f6, tractor_right_f7, tractor_right_f8
    ]
}

# --- 3. CONFIGURATION & DIMENSIONS ---
DEFAULT_GRASS_COLOR = "#0b750b"
LEFT_PASS_COLOR = "#499849"
RIGHT_PASS_COLOR = "#064d06"
PASS_SIZE = 6

# canvas.is2x() doesn't always exist in standard Pixlet environments;
# safely default to standard 32x64 unless explicitly working with a 2x setup.
IS_2X = hasattr(canvas, "is2x") and canvas.is2x()
ASSET_SIZE = 68 if IS_2X else 50
CANVAS_HEIGHT = 64 if IS_2X else 32
CANVAS_WIDTH = 128 if IS_2X else 64

# --- 4. ANIMATION LOGIC ---
def mower_animate(direction = 'left'):
    frames = []
    raw_files = TRACTOR_FRAMES.get(direction, TRACTOR_FRAMES["left"])

    RIGHT_PADDING = CANVAS_WIDTH + ASSET_SIZE if direction == 'left' else 0
    for file_data in raw_files:
        frames.append(
            render.Stack(
                children = [
                    render.Padding(
                        pad = (34, 50, 0, 0),
                        child = render.Box(width=CANVAS_WIDTH + ASSET_SIZE,
                        height=PASS_SIZE,
                        color=LEFT_PASS_COLOR if direction == 'left' else RIGHT_PASS_COLOR
                        ),
                    ),
                    render.Image(width = ASSET_SIZE, height = ASSET_SIZE, src = file_data.readall())
                ]
            )
        )

    return render.Animation(children=frames)


def renderMowerSequence():
    return render.Sequence(
        children = [
            animation.Transformation(
                child = mower_animate('left'),
                duration = 100,
                delay = 0,
                origin = animation.Origin(0.5, 0.5),
                direction = "normal",
                fill_mode = "forwards",
                keyframes = [
                    animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(CANVAS_WIDTH, 8)],
                    curve = "linear",
                    ),
                    animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(-ASSET_SIZE, 8)],
                    ),
                ],
            ),
            animation.Transformation(
                child = mower_animate('right'),
                duration = 100,
                delay = 0,
                origin = animation.Origin(0.5, 0.5),
                direction = "normal",
                fill_mode = "forwards",
                keyframes = [
                    animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(-ASSET_SIZE, 0)],
                    curve = "linear",
                    ),
                    animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(CANVAS_WIDTH, 0)],
                    ),
                ],
            ),
        ]
    )

# will evolve with seasonal changes
def renderScene():
    return renderMowerSequence()

def main(config):
    return render.Root(
        child = render.Box(
            width = CANVAS_WIDTH,
            height = CANVAS_HEIGHT,
            color = DEFAULT_GRASS_COLOR,
            child = renderScene()
        )
    )
