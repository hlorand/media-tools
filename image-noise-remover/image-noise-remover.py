#!/usr/bin/env python3

"""
Image sequence noise removal

This tool removes the noise from low-light images with image stacking. You need multiple images: you need an image sequence shot from a tripod, from the same position. The program calculates the average color for each pixel, filtering out the noise.

Usage: noise_removal.py  input_folder/  output_image.jpg
"""

__author__ = "Lorand Horvath"
__copyright__ = "Copyright 2019, hlorand.hu"
__license__ = "https://choosealicense.com/licenses/gpl-3.0/"
__version__ = "0.1"
__email__ = "email at hlorand dot hu"

import os
import cv2
import numpy
import argparse
from time import time

def stackImages(file_list):

    # Read the first image
    stacked_image = cv2.imread(file_list[0],1).astype(numpy.float32) / 255

    # Read the rest of the images and add it to the first
    for file in file_list[1:]:
        image = cv2.imread(file,1).astype(numpy.float32) / 255
        print(file)
        stacked_image += image

    # Average
    stacked_image /= len(file_list)
    stacked_image = (stacked_image*255).astype(numpy.uint8)
    
    return stacked_image


################# MAIN ################

if __name__ == '__main__':

    # Parse arguments

    parser = argparse.ArgumentParser(description='')
    parser.add_argument('input_dir', help='Input directory of images ()')
    parser.add_argument('output_image', help='Output image name')
    args = parser.parse_args()

    # Open images

    image_folder = args.input_dir
    if not os.path.exists(image_folder):
        print("ERROR {} not found!".format(image_folder))
        exit()

    file_list = os.listdir(image_folder)
    file_list = [os.path.join(image_folder, x)
                 for x in file_list if x.endswith(('.jpg', '.png','.bmp','.tif'))]

    # Stacking

    tic = time()

    print("Stacking {0} images, please wait".format( len(file_list) ))

    stacked_image = stackImages(file_list)

    # Saving

    print("Stacked {0} images in {1} seconds".format( len(file_list), (time()-tic) ))

    cv2.imwrite(str(args.output_image),stacked_image)

