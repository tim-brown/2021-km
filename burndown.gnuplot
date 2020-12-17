# vim: syntax=gnuplot

set multiplot layout 3,3

distance_left(f) = objective - f

set grid
set xdata time
isotime = "%Y-%m-%dT%H:%M"
set timefmt "%Y-%m-%dT%H:%M"

week_begin_t(t) = t - (tm_sec(t) + 60 * (tm_min(t) + 60 * (tm_hour(t) + 24 * tm_wday(t))))
month_begin_t(t) = t - (tm_sec(t) + 60 * (tm_min(t) + 60 * (tm_hour(t) + 24 * (tm_mday(t) - 1))))

days_in_month(m) = \
    m == 2 ? 28 \
  : m == 9 ? 30 \
  : m == 4 ? 30 \
  : m == 6 ? 30 \
  : m == 11 ? 30 \
  : 31
month_end_t(t) = t - (tm_sec(t) + 60 * (tm_min(t) + 60 * (tm_hour(t) + 24 * (tm_mday(t))))) + 60*60*24*days_in_month(tm_mon(t))

now = time(0)

month_begin = month_begin_t(now)
month_end = month_end_t(now)

parse_time(t) = strptime(isotime, t)

target = parse_time(target_iso)
stretch = parse_time(stretch_iso)
initial = parse_time(initial_iso)

date_line_i_t(d,q,i,o) = o - o * (q - i)/(d - i);
date_line_i_t(d,q,i,o) = o - o * (q - i)/(d - i);

target_line_i_t(q,i,o) = date_line_i_t(target, q, i, o);
stretch_line_i_t(q,i,o) = date_line_i_t(stretch, q, i, o);

target_line_t(q) = target_line_i_t(q, initial, objective)
stretch_line_t(q) = stretch_line_i_t(q, initial, objective)

target_line(q) = target_line_t(parse_time(q))
stretch_line(q) = stretch_line_t(parse_time(q))

set yrange [0:objective]
set xrange [initial:target]
s_day = 24*60*60

accumulated_data = '<awk "{km = \$2 * \$3; x+=km; print \$1, km, x}" log.tsv'

set title "Big Picture"

is_on_target_stretch(dist, dt) = distance_left(dist) <= stretch_line(dt)
is_on_target_target(dist, dt) = distance_left(dist) <= target_line(dt)

on_target_distance_left_stretch(dist, dt) = is_on_target_stretch(dist, dt) ? distance_left(dist) : (1/0);
on_target_distance_left_target(dist, dt) = (!is_on_target_stretch(dist, dt) && is_on_target_target(dist, dt)) ? distance_left(dist) : (1/0);
off_target(dist, dt) = (!is_on_target_stretch(dist, dt) && !is_on_target_target(dist, dt)) ? distance_left(dist) : (1/0);

    # accumulated_data using 1:(distance_left($3) <= stretch_line(strcol(1)) ? distance_left($3) : (1/0)) \

title_aug=sprintf("%s Target: %.2f km/d", strftime("%b %d", stretch), objective/((stretch-initial)/s_day))
title_dec=sprintf("%s Target: %.2f km/d", strftime("%b %d", target), objective/((target-initial)/s_day))

title_g="Burndown (Stretch)"
title_o="Burndown (Target)"
title_r="Off Target"
title_line="Burndown"

plot \
    accumulated_data using 1:(on_target_distance_left_stretch($3, strcol(1))) title title_g with circles lc "green", \
    accumulated_data using 1:(on_target_distance_left_target($3, strcol(1))) title title_o with circles lc "orange", \
    accumulated_data using 1:(off_target($3, strcol(1))) title title_r with circles lc "red", \
    accumulated_data using 1:(last_y=distance_left($3)) title title_line with lines lw 2 lc "black", \
    stretch_line_t(x) title title_aug lw 1.5 lc "#00aa00", \
    target_line_t(x) title title_dec lw 1.5 lc "#aa0000"


set title sprintf("%s -- %s", strftime("%F %T", month_begin), strftime("%F %T", month_end))

set yrange [*:*]

set xrange [month_begin:(month_end + s_day)]

plan_aug(s,t)=sprintf("%.2f: %.2f /d:%.2f", stretch_line_t(t),last_y-stretch_line_t(t),(last_y-stretch_line_t(t))*s_day/(t-now))
plan_dec(s,t)=sprintf("%.2f: %.2f /d:%.2f", target_line_t(t),last_y-target_line_t(t),(last_y-target_line_t(t))*s_day/(t-now))

period_end=month_end
title_aug=plan_aug("EoM", period_end);
title_dec=plan_dec("EoM", period_end);
title_g=""
title_o=""
title_r=""
title_line=""

replot

set yrange [*:*]

set title "28 days Surrounding"
period_end=now + 28 * s_day
title_aug=plan_aug("+28 day", period_end);
title_dec=plan_dec("+28 day", period_end);
set xrange [(now - 28 * s_day):period_end]

replot

set yrange [*:*]

set title "This Week"
period_end=week_begin_t(now) + (7 * s_day)
title_aug=plan_aug("Week end", period_end);
title_dec=plan_dec("Week end", period_end);
set xrange [week_begin_t(now):period_end]

replot

set yrange [*:*]

set title "Week Surrounding"
period_end=now + 7 * s_day
title_aug=plan_aug("+7 day", period_end);
title_dec=plan_dec("+7 day", period_end);
set xrange [(now + (-7 * s_day)):period_end]

lastx_s = GPVAL_DATA_X_MAX
set arrow from lastx_s,last_y to lastx_s,target_line_t(lastx_s) lc "red"
set arrow from lastx_s,last_y to lastx_s,stretch_line_t(lastx_s) lc "green"

set label sprintf("%2.2f", last_y - target_line_t(lastx_s)) at lastx_s,(last_y + target_line_t(lastx_s))/2 tc "red"
set label sprintf("%2.2f", last_y - stretch_line_t(lastx_s)) at lastx_s,(last_y + stretch_line_t(lastx_s))/2 tc "green"

plot \
    accumulated_data using 1:(on_target_distance_left_stretch($3, strcol(1))) title title_g with circles lc "green", \
    accumulated_data using 1:(on_target_distance_left_target($3, strcol(1))) title title_o with circles lc "orange", \
    accumulated_data using 1:(off_target($3, strcol(1))) title title_r with circles lc "red", \
    accumulated_data using 1:(last_y=distance_left($3)) title title_line with lines lw 2 lc "black", \
    stretch_line_t(x) title title_aug lw 1.5 lc "#00aa00", \
    target_line_t(x) title title_dec lw 1.5 lc "#aa0000", \
\
    stretch_line_i_t(x, lastx_s, last_y) title sprintf("last: %.3f km/d", last_y/((stretch - lastx_s)/s_day)) lw .5 lc "#00ff00", \
    target_line_i_t(x, lastx_s, last_y) title sprintf("last: %.3f km/d", last_y/((target - lastx_s)/s_day)) lw .5 lc "#ff0000"

set title "Day Surrounding"

period_end=now + s_day
title_aug=plan_aug("+1 day", period_end);
title_dec=plan_dec("+1 day", period_end);
set xrange [(now + (-1 * s_day)):period_end]

plot \
    accumulated_data using 1:(on_target_distance_left_stretch($3, strcol(1))) title title_g with circles lc "green", \
    accumulated_data using 1:(on_target_distance_left_target($3, strcol(1))) title title_o with circles lc "orange", \
    accumulated_data using 1:(off_target($3, strcol(1))) title title_r with circles lc "red", \
    accumulated_data using 1:(last_y=distance_left($3)) title title_line with lines lw 2 lc "black", \
    stretch_line_t(x) title title_aug lw 1.5 lc "#00aa00", \
    target_line_t(x) title title_dec lw 1.5 lc "#aa0000", \
\
    stretch_line_i_t(x, now, last_y) title sprintf("now: %.3f km/d", last_y/((stretch - now)/s_day)) lw 1 lc "#00ff00", \
    target_line_i_t(x, now, last_y) title sprintf("now: %.3f km/d", last_y/((target - now)/s_day)) lw 1 lc "#ff0000"

set title "Required Rate"
set xrange [*:*]
set yrange [*:*]
# set logscale y 1.025

plot \
accumulated_data using 1:((s_day * distance_left($3))/(stretch-parse_time(strcol(1)))) with linespoint title "", \
accumulated_data using 1:((s_day * distance_left($3))/(target-parse_time(strcol(1)))) with linespoint title ""

set title "Distance to Rate"
current_distance_remaining = distance_left(last_y)
max_x = (last_y*s_day/(stretch-now))

set xrange [0:max_x]
set xdata
set yrange [20:last_y]
set logscale y 10
# set yrange [0:*]

distance_to_rate(d, r) = (last_y - ((d-now)/s_day * r))
sequence_file = sprintf("<seq 0 .5 %d", int(max_x))

plot \
last_y - ((stretch-now)/s_day * x) with lines title "", \
last_y - ((target-now)/s_day * x) with lines title "", \
sequence_file using 1:(distance_to_rate(stretch, $1)):(sprintf("%d", distance_to_rate(stretch, column(1)))) with labels title "", \
sequence_file using 1:(distance_to_rate(target, $1)):(sprintf("%d", distance_to_rate(target, column(1)))) with labels title "" \
