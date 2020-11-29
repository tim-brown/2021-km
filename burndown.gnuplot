# vim: syntax=gnuplot
objective = 2021

# set term qt size 1600,1024
# set term qt size 2600,1600
# set term qt size 1600,1200
# set term qt size 1200,1024

distance_left(f) = objective - f;

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

# print strftime("%F %T", month_begin)
# print strftime("%F %T", month_end)

parse_time(t) = strptime(isotime, t)

dec31 = parse_time("2021-12-31T00:00")
aug31 = parse_time("2021-08-31T00:00")
initial = parse_time("2020-10-27T00:00")

date_line_i_t(d,q,i,o) = o - o * (q - i)/(d - i);
date_line_i_t(d,q,i,o) = o - o * (q - i)/(d - i);

dec31_line_i_t(q,i,o) = date_line_i_t(dec31, q, i, o);
aug31_line_i_t(q,i,o) = date_line_i_t(aug31, q, i, o);

dec31_line_t(q) = dec31_line_i_t(q, initial, objective)
aug31_line_t(q) = aug31_line_i_t(q, initial, objective)

dec31_line(q) = dec31_line_t(parse_time(q))
aug31_line(q) = aug31_line_t(parse_time(q))

set yrange [0:objective]
set xrange [initial:dec31]
s_day = 24*60*60

accumulated_data = '<awk "{km = \$2 * \$3; x+=km; print \$1, km, x}" log.tsv'

set title "Big Picture"

is_on_target_aug31(dist, dt) = distance_left(dist) <= aug31_line(dt)
is_on_target_dec31(dist, dt) = distance_left(dist) <= dec31_line(dt)

on_target_distance_left_aug31(dist, dt) = is_on_target_aug31(dist, dt) ? distance_left(dist) : (1/0);
on_target_distance_left_dec31(dist, dt) = (!is_on_target_aug31(dist, dt) && is_on_target_dec31(dist, dt)) ? distance_left(dist) : (1/0);
off_target(dist, dt) = (!is_on_target_aug31(dist, dt) && !is_on_target_dec31(dist, dt)) ? distance_left(dist) : (1/0);

    # accumulated_data using 1:(distance_left($3) <= aug31_line(strcol(1)) ? distance_left($3) : (1/0)) \

title_aug=sprintf("Aug 31 Target: %.2f km/d", objective/((aug31-initial)/s_day))
title_dec=sprintf("Dec 31 Target: %.2f km/d", objective/((dec31-initial)/s_day))

title_g="Burndown (Aug)"
title_o="Burndown (Dec)"
title_r="Off Target"
title_line="Burndown"

plot \
    accumulated_data using 1:(on_target_distance_left_aug31($3, strcol(1))) title title_g with circles lc "green", \
    accumulated_data using 1:(on_target_distance_left_dec31($3, strcol(1))) title title_o with circles lc "orange", \
    accumulated_data using 1:(off_target($3, strcol(1))) title title_r with circles lc "red", \
    accumulated_data using 1:(last_y=distance_left($3)) title title_line with lines lw 2 lc "black", \
    aug31_line_t(x) title title_aug lw 1.5 lc "#00aa00", \
    dec31_line_t(x) title title_dec lw 1.5 lc "#aa0000"


set title sprintf("%s -- %s", strftime("%F %T", month_begin), strftime("%F %T", month_end))

set yrange [*:*]

set xrange [month_begin:(month_end + s_day)]

plan_aug(s,t)=sprintf("%.2f: %.2f /d:%.2f", aug31_line_t(t),last_y-aug31_line_t(t),(last_y-aug31_line_t(t))*s_day/(t-now))
plan_dec(s,t)=sprintf("%.2f: %.2f /d:%.2f", dec31_line_t(t),last_y-dec31_line_t(t),(last_y-dec31_line_t(t))*s_day/(t-now))

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
set arrow from lastx_s,last_y to lastx_s,dec31_line_t(lastx_s) lc "red"
set arrow from lastx_s,last_y to lastx_s,aug31_line_t(lastx_s) lc "green"

set label sprintf("%2.2f", last_y - dec31_line_t(lastx_s)) at lastx_s,(last_y + dec31_line_t(lastx_s))/2 tc "red"
set label sprintf("%2.2f", last_y - aug31_line_t(lastx_s)) at lastx_s,(last_y + aug31_line_t(lastx_s))/2 tc "green"

plot \
    accumulated_data using 1:(on_target_distance_left_aug31($3, strcol(1))) title title_g with circles lc "green", \
    accumulated_data using 1:(on_target_distance_left_dec31($3, strcol(1))) title title_o with circles lc "orange", \
    accumulated_data using 1:(off_target($3, strcol(1))) title title_r with circles lc "red", \
    accumulated_data using 1:(last_y=distance_left($3)) title title_line with lines lw 2 lc "black", \
    aug31_line_t(x) title title_aug lw 1.5 lc "#00aa00", \
    dec31_line_t(x) title title_dec lw 1.5 lc "#aa0000", \
\
    aug31_line_i_t(x, lastx_s, last_y) title sprintf("last: %.3f km/d", last_y/((aug31 - lastx_s)/s_day)) lw .5 lc "#00ff00", \
    dec31_line_i_t(x, lastx_s, last_y) title sprintf("last: %.3f km/d", last_y/((dec31 - lastx_s)/s_day)) lw .5 lc "#ff0000"

set title "Day Surrounding"

period_end=now + s_day
title_aug=plan_aug("+1 day", period_end);
title_dec=plan_dec("+1 day", period_end);
set xrange [(now + (-1 * s_day)):period_end]

plot \
    accumulated_data using 1:(on_target_distance_left_aug31($3, strcol(1))) title title_g with circles lc "green", \
    accumulated_data using 1:(on_target_distance_left_dec31($3, strcol(1))) title title_o with circles lc "orange", \
    accumulated_data using 1:(off_target($3, strcol(1))) title title_r with circles lc "red", \
    accumulated_data using 1:(last_y=distance_left($3)) title title_line with lines lw 2 lc "black", \
    aug31_line_t(x) title title_aug lw 1.5 lc "#00aa00", \
    dec31_line_t(x) title title_dec lw 1.5 lc "#aa0000", \
\
    aug31_line_i_t(x, now, last_y) title sprintf("now: %.3f km/d", last_y/((aug31 - now)/s_day)) lw 1 lc "#00ff00", \
    dec31_line_i_t(x, now, last_y) title sprintf("now: %.3f km/d", last_y/((dec31 - now)/s_day)) lw 1 lc "#ff0000"

set title "Required Rate"
set xrange [*:*]
set yrange [*:*]
# set logscale y 1.025

plot \
accumulated_data using 1:((s_day * distance_left($3))/(aug31-parse_time(strcol(1)))) with linespoint title "", \
accumulated_data using 1:((s_day * distance_left($3))/(dec31-parse_time(strcol(1)))) with linespoint title ""
