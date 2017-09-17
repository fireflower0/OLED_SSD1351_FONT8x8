# OLED_SSD1351_FONT8x8

We control the following OLED with RaspberryPi and CommonLisp (SBCL).

[MARY-OB基板(OLED Board)【MARMEX-OB】](https://www.marutsu.co.jp/pc/i/104614/)

## Description

Display the character string of 8 × 8 font on the OLED.

## Circuit diagram

![CircuitDiagram](https://github.com/fireflower0/OLED_SSD1351_FONT8x8/blob/master/img/ssd1351_circuit_full.png)

## DEMO

When it is displayed cleanly it will be as follows.  

![Demo1](https://github.com/fireflower0/OLED_SSD1351_FONT8x8/blob/master/img/oled-ssd1351-font8x8_01.png)  

Caution: Characters may collapse or become chipped.  

![Demo2](https://github.com/fireflower0/OLED_SSD1351_FONT8x8/blob/master/img/oled-ssd1351-font8x8_02.png)  

## Requirement

- Common LIsp (SBCL)

## Usage

Execute it with the following command.  
Note: Quicklisp is required to run.  

    $ sbcl --load oled-ssd1351.lisp

## Installation

    $ git clone https://github.com/fireflower0/OLED_SSD1351_FONT8x8.git

## Author

[fireflower0](https://twitter.com/fireflower0)

## License

[MIT](https://choosealicense.com/licenses/mit/)
