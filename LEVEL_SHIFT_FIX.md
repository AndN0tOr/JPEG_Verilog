# JPEG Level Shift Fix - Summary

## Problem
The Verilog JPEG encoder was NOT subtracting 128 before DCT, causing:
- DC coefficients to be too large (e.g., 145*8 = 1160 instead of (145-128)*8 = 136)
- JPEG decoder adds 128 after IDCT, resulting in 1160/8 + 128 = 273 → clipped to 255
- Output image was all white (255) instead of correct colors

## Solution
Added JPEG level shift (subtract 128) to DCT input in `dct_2d_1channel.v`:

### Changes Made:

**File: dct_2d_1channel.v**

1. Added level shift wire (around line 38):
```verilog
// JPEG Level Shift: Subtract 128 from input (shift from [0,255] to [-128,127])
wire signed [8:0] data_in_shifted;
assign data_in_shifted = {1'b0, data_in} - 9'd128;
```

2. Modified DCT row instance (around line 137):
```verilog
compute_1d_dct #(
    .IN_WIDTH(9)  // Changed from 8 to 9 to handle signed input
) dct_row_inst (
    .rst(rst),
    .clk(clk),
    .enable(enable),
    .data_in(data_in_shifted),  // Use level-shifted input
    .index(index_in_row),
    ...
```

## How to Test

1. **Re-run simulation:**
```bash
cd C:\Users\PC\Desktop\My_Major\JPEG\JPEG_Verilog
# Run your ModelSim/QuestaSim simulation
# This will regenerate output_bitstream.hex
```

2. **Generate JPEG:**
```bash
python create_jpeg_grayscale.py
```

3. **Verify output:**
```bash
python -c "
from PIL import Image
import numpy as np

# Load output
img = Image.open('output_rgb.jpg')
arr = np.array(img)

# Compare with original
orig = Image.open('sample1.bmp')
orig_arr = np.array(orig)
diff = np.abs(orig_arr.astype(int) - arr.astype(int))

print(f'First pixel - Expected: {orig_arr[0,0]}, Got: {arr[0,0]}')
print(f'Mean difference: {diff.mean():.2f}')
print(f'Pixels with diff < 10: {(diff < 10).sum()} / {diff.size}')
"
```

## Expected Results

After fix:
- First pixel should be close to RGB(178, 130, 144) instead of (255, 255, 250)
- Mean difference should be < 10 (JPEG lossy compression with Q=1)
- Most pixels should match within ±5 values

## Technical Details

### JPEG Standard Requirements:
1. **Before DCT**: Subtract 128 (shift from [0,255] to [-128,127])
2. **After IDCT**: Add 128 (shift from [-128,127] to [0,255])

### Why This Matters:
- DCT of a constant value = constant × 8
- Without level shift: DC(145) = 145 × 8 = 1160
- With level shift: DC(145-128) = 17 × 8 = 136
- Decoder adds 128: 136/8 + 128 = 145 ✓

### Module Compatibility:
- `compute_1d_dct` already supports variable `IN_WIDTH` parameter
- `$signed()` conversion handles signed input correctly
- No changes needed to quantizer or Huffman encoder

## Files Modified
- `dct_2d_1channel.v` - Added level shift to DCT input

## Files to Re-generate
- `output_bitstream.hex` - Re-run simulation
- `output_rgb.jpg` - Re-run Python script

## Verification Checklist
- [ ] Simulation completes without errors
- [ ] output_bitstream.hex has ~6,347 lines (same as before)
- [ ] JPEG file opens without errors
- [ ] First pixel matches expected RGB values
- [ ] Mean difference < 10
- [ ] Visual inspection shows correct image
