;; Load packages
(load "packages.lisp" :external-format :utf-8)

(in-package :cl-cffi)

;; Load wrapper API
(load "libwiringPi.lisp" :external-format :utf-8)
(load "definition-file.lisp" :external-format :utf-8)
(load "8x8-font.lisp" :external-format :utf-8)

;; OLED Vcc Power ON
(defun oled-power-on ()
  (digitalWrite +pin-oled-vcc+ +high+))

;; OLED Vcc Power OFF
(defun oled-power-off ()
  (digitalWrite +pin-oled-vcc+ +low+))

;; SPI Data Write
(defun spi-write (data)
  (let ((count 7))
    (loop
       (if (< count 0) (return))
       (digitalWrite +pin-oled-sclk+ +low+)
       (if (equal (ldb (byte 1 count) data) 1)
           (digitalWrite +pin-oled-mosi+ +high+)
           (digitalWrite +pin-oled-mosi+ +low+))
       (digitalWrite +pin-oled-sclk+ +high+)
       (decf count))))

;; Write cmmand data
(defun oled-cd-write (mode data)
  (digitalWrite +pin-oled-cs+ +low+)
  (digitalWrite +pin-oled-sclk+ +low+)
  (if (equal mode 0)
      (digitalWrite +pin-oled-mosi+ +oled-cmd+)
      (digitalWrite +pin-oled-mosi+ +oled-data+))
  (digitalWrite +pin-oled-sclk+ +high+)
  (spi-write data)
  (digitalWrite +pin-oled-cs+ +high+))

;; All Screen black out
(defun black-out ()
  ;; Column (#X15)
  (oled-cd-write +oled-cmd+ +cmd-setcolumn+)
  (dolist (data `(#X00 #X7F))
    (oled-cd-write +oled-data+ data))
  
  ;; Row (#X75)
  (oled-cd-write +oled-cmd+ +cmd-setrow+)
  (dolist (data `(#X00 #X7F))
    (oled-cd-write +oled-data+ data))
  
  ;; Start write to ram (#XAF)
  (dotimes (count (* 128 128))
    (oled-cd-write +oled-cmd+ +cmd-writeram+)
    (dolist (data `(#X00 #X00))
      (oled-cd-write +oled-data+ data))))

;; Put char
(defun put-char (index x y rgb-bit1 rgb-bit2)
  (let (buf count2)
    ;; Column (#X15)
    (oled-cd-write +oled-cmd+ +cmd-setcolumn+)
    (oled-cd-write +oled-data+ x)
    (oled-cd-write +oled-data+ (+ x 7))

    ;; Row (#X75)
    (oled-cd-write +oled-cmd+ +cmd-setrow+)
    (oled-cd-write +oled-data+ y)
    (oled-cd-write +oled-data+ (+ y 7))
    
    ;; Start write to ram (#XAF)
    (dotimes (count1 8)
      (setf buf (aref font-8x8 index count1))
      (setf count2 7)
      (loop
         (if (< count2 0) (return))
         (oled-cd-write +oled-cmd+ +cmd-writeram+)
         (if (equal (ldb (byte 1 count2) buf) 1)
             (dolist (data `(,rgb-bit1 ,rgb-bit2))
               (oled-cd-write +oled-data+ data))
             (dolist (data `(#X00 #X00))
               (oled-cd-write +oled-data+ data)))
         (decf count2)))))

;; Draw string
(defun draw-string (str x y red green blue)
  (let (char-list rgb-bit1 rgb-bit2)
    (setf char-list (coerce str 'list))
    (setf rgb-bit1 (logior (ash red 3) (ash green -3)))
    (setf rgb-bit2 (logior (ash green -5) blue))
    (dolist (char char-list)
      (put-char (- (char-code char) #X20) x y rgb-bit1 rgb-bit2)
      (setf x (+ x 7)))))

;; SSD1351 OLED Init
(defun oled_init ()
  ;; #XA4
  (oled-cd-write +oled-cmd+ +cmd-displayalloff+)

  ;; #XFD
  (oled-cd-write +oled-cmd+ +cmd-commandlock+)
  (oled-cd-write +oled-data+ #X12)

  ;; #XFD
  (oled-cd-write +oled-cmd+ +cmd-commandlock+)
  (oled-cd-write +oled-data+ #XB1)

  ;; #XAE
  (oled-cd-write +oled-cmd+ +cmd-displayoff+)

  ;; #XB3
  (oled-cd-write +oled-cmd+ +cmd-clockdiv+)
  (oled-cd-write +oled-data+ #XF1)

  ;; #XCA
  (oled-cd-write +oled-cmd+ +cmd-muxratio+)
  (oled-cd-write +oled-data+ #X7F)

  ;; #XA2
  (oled-cd-write +oled-cmd+ +cmd-displayoffset+)
  (oled-cd-write +oled-data+ #X00)

  ;; #XA1
  (oled-cd-write +oled-cmd+ +cmd-startline+)
  (oled-cd-write +oled-data+ #X00)
  
  ;; #XA0 (65k color)
  (oled-cd-write +oled-cmd+ +cmd-setremap+)
  (oled-cd-write +oled-data+ #X74)

  ;; #XB5
  (oled-cd-write +oled-cmd+ +cmd-setgpio+)
  (oled-cd-write +oled-data+ #X00)

  ;; #XAB
  (oled-cd-write +oled-cmd+ +cmd-functionselect+)
  (oled-cd-write +oled-data+ #X01)

  ;; #XB4
  (oled-cd-write +oled-cmd+ +cmd-setvsl+)
  (dolist (data `(#XA0 #XB5 #X55))
    (oled-cd-write +oled-data+ data))

  ;; #XC1
  (oled-cd-write +oled-cmd+ +cmd-contrastabc+)
  (dolist (data `(#XC8 #X80 #XC8))
    (oled-cd-write +oled-data+ data))

  ;; #XC7
  (oled-cd-write +oled-cmd+ +cmd-contrastmaster+)
  (oled-cd-write +oled-data+ #X0F)

  ;; #XB8
  (oled-cd-write +oled-cmd+ +cmd-setgray+)
  (dolist (data `(#X02 #X03 #X04 #X05 #X06 #X07 #X08 #X09
                  #X0A #X0B #X0C #X0D #X0E #X0F #X10 #X11
                  #X12 #X13 #X15 #X17 #X19 #X1B #X1D #X1F
                  #X21 #X23 #X25 #X27 #X2A #X2D #X30 #X33
                  #X36 #X39 #X3C #X3F #X42 #X45 #X48 #X4C
                  #X50 #X54 #X58 #X5C #X60 #X64 #X68 #X6C
                  #X70 #X74 #X78 #X7D #X82 #X87 #X8C #X91
                  #X96 #X9B #XA0 #XA5 #XAA #XAF #XB4))
    (oled-cd-write +oled-data+ data))

  ;; #XB1
  (oled-cd-write +oled-cmd+ +cmd-precharge+)
  (oled-cd-write +oled-data+ #X32)

  ;; #XB2
  (oled-cd-write +oled-cmd+ +cmd-displayenhance+)
  (dolist (data `(#XA4 #X00 #X00))
    (oled-cd-write +oled-data+ data))

  ;; #XBB
  (oled-cd-write +oled-cmd+ +cmd-prechargelevel+)
  (oled-cd-write +oled-data+ #X17)

  ;; #XB6
  (oled-cd-write +oled-cmd+ +cmd-precharge2+)
  (oled-cd-write +oled-data+ #X01)

  ;; #XBE
  (oled-cd-write +oled-cmd+ +cmd-vcomh+)
  (oled-cd-write +oled-data+ #X05)

  ;; #XA6
  (oled-cd-write +oled-cmd+ +cmd-normaldisplay+)

  ;; OLED Black out
  (black-out)
  
  ;; OLED Vcc Power ON
  (oled-power-on)
  
  ;; #XAF
  (oled-cd-write +oled-cmd+ +cmd-displayon+))

;; Main function
(defun main ()
  ;; Initialize SPI
  (wiringPiSPISetup +spi-cs+ +spi-speed+)
  
  ;; Initialize GPIO
  (wiringPiSetupGpio)

  ;; GPIO Mode settings
  (pinMode +pin-oled-cs+    +output+)
  (pinMode +pin-oled-vcc+   +output+)
  (pinMode +pin-oled-reset+ +output+)
  (pinMode +pin-oled-mosi+  +output+)
  (pinMode +pin-oled-sclk+  +output+)

  ;; CS High
  (digitalWrite +pin-oled-cs+ +high+)

  ;; OLED Reset
  (digitalWrite +pin-oled-reset+ +high+)
  (delay 500)
  (digitalWrite +pin-oled-reset+ +low+)
  (delay 500)
  (digitalWrite +pin-oled-reset+ +high+)
  (delay 500)

  ;; Initialize OLED
  (oled_init)

  ;; Draw string
  (draw-string "Hello, world!" 10 10 +max-red+ +max-green+ +max-blue+)
  (draw-string "Hello, world!" 10 20 +max-red+ #X00 #X00)
  (draw-string "Hello, world!" 10 30 #X00 +max-green+ #X00)
  (draw-string "Hello, world!" 10 40 #X00 #X00 +max-blue+)
  (draw-string "Hello, world!" 10 50 #X00 +max-green+ +max-blue+)
  (draw-string "Hello, world!" 10 60 +max-red+ #X00 +max-blue+)
  (draw-string "Hello, world!" 10 70 +max-red+ +max-green+ #X00)
  
  ;; Delay
  (delay 10000)

  ;; OLED Black out
  (black-out)
  
  ;; OLED Vcc Power OFF
  (oled-power-off))

;; Executable!!!
(main)

