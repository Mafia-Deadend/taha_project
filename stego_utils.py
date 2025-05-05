import io
import random
from PIL import Image

# -- Text Steganography Utilities --
def text_to_bin(text: str) -> str:
    """Convert text to a binary string."""
    return ''.join(format(ord(char), '08b') for char in text)

def bin_to_text(binary: str) -> str:
    """Convert binary string to text."""
    return ''.join(chr(int(binary[i:i+8], 2)) for i in range(0, len(binary), 8))


def hide_text_in_image(image_stream: io.BytesIO, text: str) -> io.BytesIO:
    """
    Hide text in an image using LSB steganography.
    :param image_stream: input image file-like object
    :param text: text to hide
    :return: BytesIO containing PNG image with hidden text
    """
    img = Image.open(image_stream).convert('RGB')
    binary_text = text_to_bin(text) + '1111111111111110'  # delimiter
    binary_index = 0
    pixels = img.load()

    for y in range(img.height):
        for x in range(img.width):
            if binary_index >= len(binary_text):
                break

            r, g, b = pixels[x, y]
            # modify r, g, b LSBs
            r = (r & ~1) | int(binary_text[binary_index]); binary_index += 1
            if binary_index < len(binary_text):
                g = (g & ~1) | int(binary_text[binary_index]); binary_index += 1
            if binary_index < len(binary_text):
                b = (b & ~1) | int(binary_text[binary_index]); binary_index += 1

            pixels[x, y] = (r, g, b)
        if binary_index >= len(binary_text):
            break

    output = io.BytesIO()
    img.save(output, format='PNG')
    output.seek(0)
    return output


def extract_text_from_image(image_stream: io.BytesIO) -> str:
    """
    Extract hidden text from an image using LSB steganography.
    :param image_stream: input stego image file-like object
    :return: extracted text
    """
    img = Image.open(image_stream).convert('RGB')
    pixels = img.load()
    binary_data = ''

    for y in range(img.height):
        for x in range(img.width):
            r, g, b = pixels[x, y]
            binary_data += str(r & 1)
            binary_data += str(g & 1)
            binary_data += str(b & 1)
            # check delimiter
            if '1111111111111110' in binary_data:
                binary_data = binary_data[:binary_data.index('1111111111111110')]
                break
        else:
            continue
        break

    return bin_to_text(binary_data)

# -- Image Steganography Utilities --
def int_to_bin(value: int, bits: int = 8) -> str:
    """Convert an integer to a binary string of fixed length."""
    return format(value, f'0{bits}b')

def bin_to_int(binary: str) -> int:
    """Convert a binary string to an integer."""
    return int(binary, 2)


def hide_image_in_image(cover_stream: io.BytesIO, secret_stream: io.BytesIO, seed: int = 42) -> io.BytesIO:
    """
    Embed a secret image into a cover image using LSB steganography.
    :param cover_stream: input cover image file-like object
    :param secret_stream: input secret image file-like object
    :param seed: random seed for slot selection
    :return: BytesIO containing the stego image
    """
    cover_img = Image.open(cover_stream).convert('RGB')
    secret_img = Image.open(secret_stream).convert('RGB')
    cover_pixels = cover_img.load()
    secret_pixels = secret_img.load()
    cover_w, cover_h = cover_img.size
    secret_w, secret_h = secret_img.size

    # store dimensions in first two pixels
    cover_pixels[0, 0] = (secret_w // 256, secret_w % 256, cover_pixels[0, 0][2])
    cover_pixels[0, 1] = (secret_h // 256, secret_h % 256, cover_pixels[0, 1][2])

    random.seed(seed)
    slots = [(x, y) for y in range(2, cover_h) for x in range(cover_w)]
    chosen = random.sample(slots, secret_w * secret_h)

    for idx, (x, y) in enumerate(chosen):
        sx = idx % secret_w
        sy = idx // secret_w
        r, g, b = cover_pixels[x, y]
        sr, sg, sb = secret_pixels[sx, sy]
        # embed high 4 bits of secret into low bits of cover
        new_r = int_to_bin(r)[:-4] + int_to_bin(sr)[:4]
        new_g = int_to_bin(g)[:-4] + int_to_bin(sg)[:4]
        new_b = int_to_bin(b)[:-4] + int_to_bin(sb)[:4]
        cover_pixels[x, y] = (bin_to_int(new_r), bin_to_int(new_g), bin_to_int(new_b))

    output = io.BytesIO()
    cover_img.save(output, format='PNG')
    output.seek(0)
    return output


def extract_image_from_image(stego_stream: io.BytesIO, seed: int = 42) -> io.BytesIO:
    """
    Extract a secret image from a stego image.
    :param stego_stream: input stego image file-like object
    :param seed: random seed used during embedding
    :return: BytesIO containing the extracted secret image
    """
    img = Image.open(stego_stream).convert('RGB')
    pixels = img.load()
    w, h = img.size

    # retrieve dimensions
    sw = pixels[0,0][0] * 256 + pixels[0,0][1]
    sh = pixels[0,1][0] * 256 + pixels[0,1][1]

    random.seed(seed)
    slots = [(x, y) for y in range(2, h) for x in range(w)]
    chosen = random.sample(slots, sw * sh)

    secret_img = Image.new('RGB', (sw, sh))
    secret_pixels = secret_img.load()

    for idx, (x, y) in enumerate(chosen):
        sx = idx % sw
        sy = idx // sw
        r, g, b = pixels[x, y]
        sr = bin_to_int(int_to_bin(r)[-4:] + '0000')
        sg = bin_to_int(int_to_bin(g)[-4:] + '0000')
        sb = bin_to_int(int_to_bin(b)[-4:] + '0000')
        secret_pixels[sx, sy] = (sr, sg, sb)

    output = io.BytesIO()
    secret_img.save(output, format='PNG')
    output.seek(0)
    return output
