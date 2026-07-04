#include <stdlib.h>
#include <zephyr/kernel.h>

#include <zmk/display.h>
#include <zmk/event_manager.h>
#include <zmk/activity.h>
#include <zmk/events/activity_state_changed.h>

#include "animation.h"

LV_IMG_DECLARE(crystal_01);
LV_IMG_DECLARE(crystal_02);
LV_IMG_DECLARE(crystal_03);
LV_IMG_DECLARE(crystal_04);
LV_IMG_DECLARE(crystal_05);
LV_IMG_DECLARE(crystal_06);
LV_IMG_DECLARE(crystal_07);
LV_IMG_DECLARE(crystal_08);
LV_IMG_DECLARE(crystal_09);
LV_IMG_DECLARE(crystal_10);
LV_IMG_DECLARE(crystal_11);
LV_IMG_DECLARE(crystal_12);
LV_IMG_DECLARE(crystal_13);
LV_IMG_DECLARE(crystal_14);
LV_IMG_DECLARE(crystal_15);
LV_IMG_DECLARE(crystal_16);

const lv_img_dsc_t *anim_imgs[] = {
    &crystal_01, &crystal_02, &crystal_03, &crystal_04, &crystal_05, &crystal_06,
    &crystal_07, &crystal_08, &crystal_09, &crystal_10, &crystal_11, &crystal_12,
    &crystal_13, &crystal_14, &crystal_15, &crystal_16,
};

#if IS_ENABLED(CONFIG_NICE_VIEW_GEM_ANIMATION)
/* Handle to the running animation so activity changes can pause/resume it. */
static lv_obj_t *animation_img = NULL;

static void animation_set_running(bool running) {
    if (animation_img == NULL) {
        return;
    }
    if (running) {
        /* Resume cycling through the frames. lv_animimg_start re-arms the intact
         * template anim, so the flap picks back up. */
        lv_animimg_start(animation_img);
    } else {
        /* Idle/sleep: stop the frame cycler so the panel stops refreshing (the
         * update traffic is what costs power on this reflective display). The
         * current frame stays on screen and the rest of the status is untouched. */
        lv_anim_del(animation_img, NULL);
    }
}

struct animation_activity_state {
    enum zmk_activity_state state;
};

static void animation_activity_update_cb(struct animation_activity_state state) {
    animation_set_running(state.state == ZMK_ACTIVITY_ACTIVE);
}

static struct animation_activity_state animation_activity_get_state(const zmk_event_t *eh) {
    const struct zmk_activity_state_changed *ev = as_zmk_activity_state_changed(eh);
    return (struct animation_activity_state){
        .state = (ev != NULL) ? ev->state : zmk_activity_get_state()};
}

ZMK_DISPLAY_WIDGET_LISTENER(animation_activity, struct animation_activity_state,
                            animation_activity_update_cb, animation_activity_get_state);
ZMK_SUBSCRIPTION(animation_activity, zmk_activity_state_changed);
#endif

void draw_animation(lv_obj_t *canvas) {
#if IS_ENABLED(CONFIG_NICE_VIEW_GEM_ANIMATION)
    lv_obj_t *art = lv_animimg_create(canvas);
    lv_obj_center(art);

    lv_animimg_set_src(art, (const void **)anim_imgs, 16);
    lv_animimg_set_duration(art, CONFIG_NICE_VIEW_GEM_ANIMATION_MS);
    lv_animimg_set_repeat_count(art, LV_ANIM_REPEAT_INFINITE);
    lv_animimg_start(art);

    /* Remember the object and start listening for activity so the animation
     * pauses when the keyboard goes idle and resumes on the next keypress. */
    animation_img = art;
    animation_activity_init();
#else
    lv_obj_t *art = lv_img_create(canvas);

    int length = sizeof(anim_imgs) / sizeof(anim_imgs[0]);
    srand(k_uptime_get_32());
    int random_index = rand() % length;

    lv_img_set_src(art, anim_imgs[random_index]);
#endif

    lv_obj_align(art, LV_ALIGN_TOP_LEFT, 36, 0);
}
