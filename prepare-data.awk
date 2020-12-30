
{
km = $2 * $3;
x+=km;
print $1, km, x
}

END {
print strftime("%Y-%m-%dT%H:%M", systime()), 0, x;
}

