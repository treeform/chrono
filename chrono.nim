## Chrono a Timestamps, Calendars, and Timezones library for nim.

##
## Format spesification
##
## ===========  =================================================================================  ================================================
## Specifier    Description                                                                        Example
## ===========  =================================================================================  ================================================
## {year}       Year in as many digits as needed. Can be negative.                                 ``12012/9/3 -> 12012``
## {year/2}     Two digit year, 0-30 represents 2000-2030 while 30-99 is 1930 to 1999.             ``2012/9/3 -> 12``
## {year/4}     Four digits of the year. Years 0 - 9999.                                           ``2012/9/3 -> 2012``
## {month}      Month in digits 1-12                                                               ``2012/9/3 -> 9``
## {month/2}    Month in two digits 01-12                                                          ``2012/9/3 -> 09``
## {month/n}    Full name of month                                                                 ``September -> September``
## {month/n/3}  Three letter name of month                                                         ``September -> Sep``
## {day}        Day in digits 1-31                                                                 ``2012/9/3 -> 3``
## {day/2}      Day in two digits 01-31                                                            ``2012/9/3 -> 03``
## {hour}       Hour in digits 0-23                                                                ``09:08:07 -> 9``
## {hour/2}     Hour in two digits 00-23                                                           ``09:08:07 -> 09``
## {hour/2/ap}  Hour as 12-hour am/pm as digits 1-12                                               ``13:08:07 -> 1``
## {hour/2/ap}  Hour as 12-hour am/pm as two digits 01-12                                          ``13:08:07 -> 01``
## {am/pm}      Based on hour outputs "am" or "pm"                                                 ``13:08:07 -> pm``
## {minute}     Minute in digits 0-59                                                              ``09:08:07 -> 8``
## {minute/2}   Minute in two digits 0-59                                                          ``09:08:07 -> 08``
## {second}     Second in digits 0-59                                                              ``09:08:07 -> 7``
## {second/2}   Second in two digits 0-59                                                          ``09:08:07 -> 07``
## {weekday}    Full name of weekday                                                               ``Saturday -> Saturday``
## {weekday/3}  Three letter of name of weekday                                                    ``Saturday -> Sat``
## {weekday/2}  Two letter of name of weekday                                                      ``Saturday -> Sa``
## {tzName}     Timezone name (can't be parsed)                                                    ``America/Los_Angeles``
## {dstName}    Daylight savings name or standard name (can't be parsed)                           ``PDT``
## ============ =================================================================================  ================================================
##
## Any string that is not in {} considered to not be part of the format and is just inserted.
## ``"{year/4} and {month/2} and {day/2}" -> "1988 and 02 and 09"``
##



include chrono/calendars
include chrono/timestamps
include chrono/timezones
