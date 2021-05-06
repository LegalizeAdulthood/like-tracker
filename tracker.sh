# Zoe Phin, v2.0 - 2021/02/20
 
require() { sudo apt-get install -y gnuplot; }
 
collect() {
    url="https://www.youtube.com"
    while true; do
        for vid in $(wget -qO- "$url/c/WhiteHouse/videos" | grep -o 'watch?v=[^"]*'); do
            wget -qO- $url/$vid | egrep -o '[0-9,]* (views|likes|dislikes)' |\
            sed -n 1~2p | tr -d '[:alpha:],\n' |\
            awk -vL=$url/$vid -vD="$(date +"%s %x,%R:%S" | tr -d '\n')" '
                NF==3 { printf "%s %s %9s %9s %9s\n", L, D, $1, $2, $3 }'
        done
        sleep $(seq 60 120 | shuf | head -1)
    done | tee -a data.csv
}
 
dislikes() {
    for vid in $(cut -c1-44 data.csv | sort -u); do
        awk -vv=$vid 'BEGIN { print v } $1==v { 
            Diff=$6-Last
            if (Diff < 0) printf "%s %+7d\n", $3, Lost+=Diff 
            Last=$6
        } END {
            printf "%-19s %7d\n\n", "Total", Lost
        }' data.csv
    done | awk '{ print } $1=="Total" { GT+=$2 } 
        END { printf "%-17s %9d\n", "Grand Total", GT 
    }'
}
 
plot() { n=0
    for vid in $(cut -c1-44 data.csv | sort -u); do let n++
        awk -vv=$vid '$1==v {print $2" "$4" "$5" "$6}' data.csv > plot.csv
        echo "set term png size 740,740
        set key top left
        set grid xtics ytics
        set title noenhanced '$vid'
        set xdata time
        set timefmt '%s'
        set xtics format '%Hh'
        plot 'plot.csv' u 1:2 t 'Views'    w lines lc rgb 'black' lw 2,\
                     '' u 1:3 t 'Likes'    w lines lc rgb 'green' lw 2,\
                     '' u 1:4 t 'Dislikes' w lines lc rgb 'red'   lw 2
        " | gnuplot > example${n}.png 
    done
}
