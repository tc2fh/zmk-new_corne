# A nice!view

The nice!view is a low-power, high refresh rate display meant to replace I2C OLEDs traditionally used.

This shield requires that an `&nice_view_spi` labeled SPI bus is provided with _at least_ MOSI, SCK, and CS pins defined.

## Animation: a hummingbird (not the gem)

Despite the `nice_view_gem` name, this shield renders a **hummingbird**
animation ([`assets/crystal.c`](assets/crystal.c)), not the upstream
gem/crystal. It plays on the peripheral half, is drawn so the head angles
up, pauses when the keyboard goes idle (`widgets/animation.c`), and follows
the display's white-on-black theme.
