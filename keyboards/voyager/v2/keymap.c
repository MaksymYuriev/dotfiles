#include QMK_KEYBOARD_H
#include "version.h"
#ifndef HCS
#define HCS(report) host_consumer_send(record->event.pressed ? report : 0); return false
#endif
#define MOON_LED_LEVEL LED_LEVEL
#ifndef ZSA_SAFE_RANGE
#define ZSA_SAFE_RANGE SAFE_RANGE
#endif

enum custom_keycodes {
  RGB_SLD = ZSA_SAFE_RANGE,
  MAC_MISSION_CONTROL,
  MAC_LOCK,
  SEL_LINE,   // select current line: Cmd+Left, Shift+Cmd+Right
  CLR_LINE,   // clear current line: Cmd+Right, Cmd+Backspace
};




const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  [0] = LAYOUT_voyager(
    CW_TOGG,        KC_1,           KC_2,           KC_3,           KC_4,           KC_5,                                           KC_6,           KC_7,           KC_8,           KC_9,           KC_0,           KC_MINUS,       
    KC_ESCAPE,      KC_Q,           KC_W,           MEH_T(KC_E),    KC_R,           KC_T,                                           KC_Y,           KC_U,           MEH_T(KC_I),    KC_O,           KC_P,           KC_LBRC,        
    MT(MOD_LSFT, KC_RBRC),MT(MOD_LCTL, KC_A),MT(MOD_LALT, KC_S),MT(MOD_LGUI, KC_D),MT(MOD_LSFT, KC_F),KC_G,                                           KC_H,           MT(MOD_RSFT, KC_J),MT(MOD_RGUI, KC_K),MT(MOD_RALT, KC_L),MT(MOD_RCTL, KC_SCLN),MT(MOD_RSFT, KC_QUOTE),
    KC_F18,         LT(3, KC_Z),    KC_X,           KC_C,           KC_V,           KC_B,                                           KC_N,           KC_M,           KC_COMMA,       KC_DOT,         LT(3, KC_SLASH),KC_F19,         
                                                    KC_SPACE,       MT(MOD_LGUI, KC_BSPC),                                LT(1, KC_ENTER),LT(2, KC_TAB)
  ),
  [1] = LAYOUT_voyager(
    KC_ESCAPE,      KC_F1,          KC_F2,          KC_F3,          KC_F4,          KC_F5,                                          KC_F6,          KC_F7,          KC_F8,          KC_F9,          KC_F10,         KC_F11,         
    KC_GRAVE,       KC_EXLM,        KC_AT,          KC_HASH,        KC_DLR,         KC_PERC,                                        KC_CIRC,        KC_AMPR,        KC_ASTR,        KC_LPRN,        KC_RPRN,        KC_F12,         
    KC_TILD,        KC_LABK,        KC_LCBR,        KC_LBRC,        KC_LPRN,        KC_EQUAL,                                       KC_MINUS,       KC_RPRN,        KC_RBRC,        KC_RCBR,        KC_RABK,        KC_BSPC,        
    KC_MINUS,       KC_BSLS,        KC_PIPE,        KC_PLUS,        KC_UNDS,        KC_QUES,                                        KC_COLN,        KC_SCLN,        KC_QUOTE,       KC_DQUO,        KC_SLASH,       KC_ENTER,       
                                                    KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_LEFT_SHIFT
  ),
  [2] = LAYOUT_voyager(
    RGB_TOG,        TOGGLE_LAYER_COLOR,RGB_MODE_FORWARD,RGB_SLD,        RGB_VAD,        RGB_VAI,                                        KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, LGUI(KC_Z),     LGUI(KC_X),     LGUI(KC_C),     LGUI(KC_V),     LSFT(LGUI(KC_Z)),                               KC_TRANSPARENT, KC_HOME,        KC_PGDN,        KC_END,         KC_PAGE_UP,     KC_F12,         
    KC_TRANSPARENT, KC_LEFT_CTRL,   KC_LEFT_ALT,    KC_LEFT_GUI,    KC_LEFT_SHIFT,  KC_DELETE,                                      KC_LEFT,        KC_DOWN,        KC_UP,          KC_RIGHT,       KC_LEFT_ALT,    KC_TRANSPARENT, 
    KC_TRANSPARENT, SEL_LINE,       CLR_LINE,       LALT(KC_BSPC),  LGUI(KC_A),     KC_TRANSPARENT,                                 KC_TRANSPARENT, LALT(LGUI(KC_LEFT)),LALT(LGUI(KC_RIGHT)),KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
                                                    KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT
  ),
  [3] = LAYOUT_voyager(
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_F14,         KC_F15,         KC_AUDIO_VOL_DOWN,KC_AUDIO_VOL_UP,KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_LEFT_GUI,    KC_TILD,        KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_MEDIA_PREV_TRACK,KC_MEDIA_PLAY_PAUSE,KC_MEDIA_NEXT_TRACK,KC_AUDIO_MUTE,  KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_SYSTEM_POWER,KC_SYSTEM_SLEEP,MAC_LOCK,       KC_TRANSPARENT,                                 KC_TRANSPARENT, MAC_MISSION_CONTROL,KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
                                                    KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT
  ),
};


#ifdef CHORDAL_HOLD
// Handedness for Chordal Hold. '*' = exempt (works with either hand):
// thumbs (layer keys + Cmd/Backspace), outer Shift keys, Z and / layer keys.
const char chordal_hold_layout[MATRIX_ROWS][MATRIX_COLS] PROGMEM = LAYOUT_voyager(
  'L', 'L', 'L', 'L', 'L', 'L',                 'R', 'R', 'R', 'R', 'R', 'R',
  'L', 'L', 'L', 'L', 'L', 'L',                 'R', 'R', 'R', 'R', 'R', 'R',
  '*', 'L', 'L', 'L', 'L', 'L',                 'R', 'R', 'R', 'R', 'R', '*',
  'L', '*', 'L', 'L', 'L', 'L',                 'R', 'R', 'R', 'R', '*', 'R',
                      '*', '*',                 '*', '*'
);
#endif



uint16_t get_tapping_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case MEH_T(KC_E):
            return TAPPING_TERM -40;
        case MT(MOD_LCTL, KC_A):
            return TAPPING_TERM -30;
        case MT(MOD_LALT, KC_S):
            return TAPPING_TERM -30;
        case MT(MOD_LGUI, KC_D):
            return TAPPING_TERM -30;
        case MT(MOD_LSFT, KC_F):
            return TAPPING_TERM -60;
        case KC_SPACE:
            return TAPPING_TERM -60;
        case MEH_T(KC_I):
            return TAPPING_TERM -40;
        case MT(MOD_RSFT, KC_J):
            return TAPPING_TERM -60;
        case MT(MOD_RGUI, KC_K):
            return TAPPING_TERM -30;
        case MT(MOD_RALT, KC_L):
            return TAPPING_TERM -30;
        case MT(MOD_RCTL, KC_SCLN):
            return TAPPING_TERM -30;
        case LT(2, KC_TAB):
            return TAPPING_TERM -60;
        default:
            return TAPPING_TERM;
    }
}


extern rgb_config_t rgb_matrix_config;

RGB hsv_to_rgb_with_value(HSV hsv) {
  RGB rgb = hsv_to_rgb( hsv );
  float f = (float)rgb_matrix_config.hsv.v / UINT8_MAX;
  return (RGB){ f * rgb.r, f * rgb.g, f * rgb.b };
}

void keyboard_post_init_user(void) {
  rgb_matrix_enable();
}

const uint8_t PROGMEM ledmap[][RGB_MATRIX_LED_COUNT][3] = {
    [1] = { {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {164,146,255}, {0,0,0}, {164,146,255} },

    [2] = { {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0} },

    [3] = { {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0} },

};

void set_layer_color(int layer) {
  for (int i = 0; i < RGB_MATRIX_LED_COUNT; i++) {
    HSV hsv = {
      .h = pgm_read_byte(&ledmap[layer][i][0]),
      .s = pgm_read_byte(&ledmap[layer][i][1]),
      .v = pgm_read_byte(&ledmap[layer][i][2]),
    };
    if (!hsv.h && !hsv.s && !hsv.v) {
        rgb_matrix_set_color( i, 0, 0, 0 );
    } else {
        RGB rgb = hsv_to_rgb_with_value(hsv);
        rgb_matrix_set_color(i, rgb.r, rgb.g, rgb.b);
    }
  }
}

bool rgb_matrix_indicators_user(void) {
  if (rawhid_state.rgb_control) {
      return false;
  }
  if (!keyboard_config.disable_layer_led) { 
    switch (biton32(layer_state)) {
      case 1:
        set_layer_color(1);
        break;
      case 2:
        set_layer_color(2);
        break;
      case 3:
        set_layer_color(3);
        break;
     default:
        if (rgb_matrix_get_flags() == LED_FLAG_NONE) {
          rgb_matrix_set_color_all(0, 0, 0);
        }
    }
  } else {
    if (rgb_matrix_get_flags() == LED_FLAG_NONE) {
      rgb_matrix_set_color_all(0, 0, 0);
    }
  }

  return true;
}





bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {
    case MAC_MISSION_CONTROL:
      HCS(0x29F);
    case MAC_LOCK:
      HCS(0x19E);

    case SEL_LINE:
      if (record->event.pressed) {
        tap_code16(LGUI(KC_LEFT));
        tap_code16(LSFT(LGUI(KC_RIGHT)));
      }
      return false;
    case CLR_LINE:
      if (record->event.pressed) {
        tap_code16(LGUI(KC_RIGHT));
        tap_code16(LGUI(KC_BSPC));
      }
      return false;
    case RGB_SLD:
      if (record->event.pressed) {
        rgblight_mode(1);
      }
      return false;
  }
  return true;
}
