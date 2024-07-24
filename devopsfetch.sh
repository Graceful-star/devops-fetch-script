#!/bin/bash

create_table() {
    local header="$1"
    local data="$2"
    local width=$(echo "$header" | awk '{print NF}')
    local sep=$(printf '+%0.s-' $(seq 1 $width) | sed 's/-/+/g')
    
    echo "$sep"
    echo "$header" | awk '{for(i=1;i<=NF;i++) printf "| %-20s ", $i; print "|"}'
    echo "$sep"
    echo "$data" | awk '{for(i=1;i<=NF;i++) printf "| %-20s ", $i; print "|"}'
    echo "$sep"
}

get_ports() {
    if [ -z "$1" ]; then
        echo "Active Ports and Services:"
        header="PROTOCOL LOCAL_ADDRESS:PORT PROCESS"
        data=$(ss -tuln | awk 'NR>1 {split($5,a,":"); print $1, $5, $7}' | sort -k2 -n)
        create_table "$header" "$data"
    else
        echo "Information for port $1:"
        header="PROTOCOL LOCAL_ADDRESS:PORT PROCESS"
        data=$(ss -tuln | awk -v port="$1" '$5 ~ ":"port"$" {print $1, $5, $7}')
        create_table "$header" "$data"
    fi
}

get_docker_info() {
    if [ -z "$1" ]; then
        echo "Docker Images:"
        header="REPOSITORY TAG IMAGE_ID CREATED SIZE"
        data=$(docker images --format "{{.Repository}} {{.Tag}} {{.ID}} {{.CreatedSince}} {{.Size}}")
        create_table "$header" "$data"
        
        echo "Docker Containers:"
        header="CONTAINER_ID NAME STATUS PORTS"
        data=$(docker ps -a --format "{{.ID}} {{.Names}} {{.Status}} {{.Ports}}")
        create_table "$header" "$data"
    else
        echo "Information for container $1:"
        docker inspect "$1" | jq '.[0] | {Id, Name, State, Image, Mounts}'
    fi
}

get_nginx_info() {
    if [ -z "$1" ]; then
        echo "Nginx Domains and Ports:"
        header="DOMAIN PORT"
        data=$(grep -r -h server_name /etc/nginx/sites-enabled/ | awk '{print $2}' | sed 's/;//' | 
               while read domain; do
                   port=$(grep -r -h listen /etc/nginx/sites-enabled/ | grep -B1 "$domain" | awk '{print $2}' | sed 's/;//' | head -1)
                   echo "$domain $port"
               done)
        create_table "$header" "$data"
    else
        echo "Nginx configuration for domain $1:"
        grep -r -A 10 "server_name $1" /etc/nginx/sites-enabled/ | sed 's/^/  /'
    fi
}

get_user_info() {
    if [ -z "$1" ]; then
        echo "Users and Last Login Times:"
        header="USER LAST_LOGIN FROM"
        data=$(last -w | awk 'NR>1 {print $1, $4" "$5" "$6, $3}' | sort | uniq)
        create_table "$header" "$data"
    else
        echo "Information for user $1:"
        id "$1" | sed 's/^/  /'
        echo "Last 5 logins:"
        last "$1" | head -n 5 | sed 's/^/  /'
    fi
}

filter_by_time() {
    start_time="$1"
    end_time="$2"
    while IFS= read -r line; do
        timestamp=$(echo "$line" | awk '{print $1, $2}')
        if [[ "$timestamp" > "$start_time" && "$timestamp" < "$end_time" ]]; then
            echo "$line"
        fi
    done
}

# Main script logic
port=""
docker=""
nginx=""
user=""
time_range=""

while getopts "p:d:n:u:t:h" opt; do
    case ${opt} in
        p ) port="$OPTARG" ;;
        d ) docker="$OPTARG" ;;
        n ) nginx="$OPTARG" ;;
        u ) user="$OPTARG" ;;
        t ) time_range="$OPTARG" ;;
        h )
            echo "Usage: $0 [-p port] [-d docker] [-n nginx] [-u user] [-t start_time-end_time]"
            echo "  -p: Display port information"
            echo "  -d: Display Docker information"
            echo "  -n: Display Nginx information"
            echo "  -u: Display user information"
            echo "  -t: Specify time range for activities (format: YYYY-MM-DD HH:MM:SS)"
            exit 0
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
    esac
done

if [ -n "$time_range" ]; then
    start_time=$(echo "$time_range" | cut -d'-' -f1)
    end_time=$(echo "$time_range" | cut -d'-' -f2)
fi

# Execute requested functions
[ -n "$port" ] && get_ports "$port" | ([ -n "$time_range" ] && filter_by_time "$start_time" "$end_time" || cat)
[ -n "$docker" ] && get_docker_info "$docker" | ([ -n "$time_range" ] && filter_by_time "$start_time" "$end_time" || cat)
[ -n "$nginx" ] && get_nginx_info "$nginx" | ([ -n "$time_range" ] && filter_by_time "$start_time" "$end_time" || cat)
[ -n "$user" ] && get_user_info "$user" | ([ -n "$time_range" ] && filter_by_time "$start_time" "$end_time" || cat)

# If no options provided, show all information
if [ -z "$port" ] && [ -z "$docker" ] && [ -z "$nginx" ] && [ -z "$user" ]; then
    get_ports
    get_docker_info
    get_nginx_info
    get_user_info
fi
# #!/bin/bash

# format_table() {
#     column -t -s $'\t' | sed 's/^/  /'
# }

# get_ports() {
#     if [ -z "$1" ]; then
#         echo "Active Ports and Services:"
#         (echo -e "PROTOCOL\tLOCAL_ADDRESS:PORT\tPROCESS" && 
#          ss -tuln | awk 'NR>1 {split($5,a,":"); print $1"\t"$5"\t"$7}' | sort -k2 -n) | format_table
#     else
#         echo "Information for port $1:"
#         ss -tuln | awk -v port="$1" '$5 ~ ":"port"$" {split($5,a,":"); print $1"\t"$5"\t"$7}' | format_table
#     fi
# }

# get_docker_info() {
#     if [ -z "$1" ]; then
#         echo "Docker Images:"
#         (echo -e "REPOSITORY\tTAG\tIMAGE_ID\tCREATED\tSIZE" && 
#          docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}") | format_table
#         echo "Docker Containers:"
#         (echo -e "CONTAINER_ID\tNAME\tSTATUS\tPORTS" && 
#          docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}") | format_table
#     else
#         echo "Information for container $1:"
#         docker inspect "$1" | jq '.[0] | {Id, Name, State, Image, Mounts}'
#     fi
# }

# get_nginx_info() {
#     if [ -z "$1" ]; then
#         echo "Nginx Domains and Ports:"
#         (echo -e "DOMAIN\tPORT" && 
#          grep -r -h server_name /etc/nginx/sites-enabled/ | awk '{print $2}' | sed 's/;//' | 
#          while read domain; do
#              port=$(grep -r -h listen /etc/nginx/sites-enabled/ | grep -B1 "$domain" | awk '{print $2}' | sed 's/;//' | head -1)
#              echo -e "$domain\t$port"
#          done) | format_table
#     else
#         echo "Nginx configuration for domain $1:"
#         grep -r -A 10 "server_name $1" /etc/nginx/sites-enabled/ | sed 's/^/  /'
#     fi
# }

# get_user_info() {
#     if [ -z "$1" ]; then
#         echo "Users and Last Login Times:"
#         (echo -e "USER\tLAST_LOGIN\tFROM" && 
#          last -w | awk 'NR>1 {print $1"\t"$4" "$5" "$6"\t"$3}' | sort | uniq) | format_table
#     else
#         echo "Information for user $1:"
#         id "$1" | sed 's/^/  /'
#         echo "Last 5 logins:"
#         last "$1" | head -n 5 | sed 's/^/  /'
#     fi
# }

# filter_by_time() {
#     start_time="$1"
#     end_time="$2"
#     while IFS= read -r line; do
#         timestamp=$(echo "$line" | awk '{print $1, $2}')
#         if [[ "$timestamp" > "$start_time" && "$timestamp" < "$end_time" ]]; then
#             echo "$line"
#         fi
#     done
# }

# # Main script logic
# port=""
# docker=""
# nginx=""
# user=""
# time_range=""

# while getopts "p:d:n:u:t:h" opt; do
#     case ${opt} in
#         p ) port="$OPTARG" ;;
#         d ) docker="$OPTARG" ;;
#         n ) nginx="$OPTARG" ;;
#         u ) user="$OPTARG" ;;
#         t ) time_range="$OPTARG" ;;
#         h )
#             echo "Usage: $0 [-p port] [-d docker] [-n nginx] [-u user] [-t start_time-end_time]"
#             echo "  -p: Display port information"
#             echo "  -d: Display Docker information"
#             echo "  -n: Display Nginx information"
#             echo "  -u: Display user information"
#             echo "  -t: Specify time range for activities (format: YYYY-MM-DD HH:MM:SS)"
#             exit 0
#             ;;
#         \? )
#             echo "Invalid Option: -$OPTARG" 1>&2
#             exit 1
#             ;;
#     esac
# done

# if [ -n "$time_range" ]; then
#     start_time=$(echo "$time_range" | cut -d'-' -f1)
#     end_time=$(echo "$time_range" | cut -d'-' -f2)
# fi

# # Execute requested functions
# [ -n "$port" ] && get_ports "$port" | ([ -n "$time_range" ] && filter_by_time "$start_time" "$end_time" || cat)
# [ -n "$docker" ] && get_docker_info "$docker" | ([ -n "$time_range" ] && filter_by_time "$start_time" "$end_time" || cat)
# [ -n "$nginx" ] && get_nginx_info "$nginx" | ([ -n "$time_range" ] && filter_by_time "$start_time" "$end_time" || cat)
# [ -n "$user" ] && get_user_info "$user" | ([ -n "$time_range" ] && filter_by_time "$start_time" "$end_time" || cat)

# # If no options provided, show all information
# if [ -z "$port" ] && [ -z "$docker" ] && [ -z "$nginx" ] && [ -z "$user" ]; then
#     get_ports
#     get_docker_info
#     get_nginx_info
#     get_user_info
# fi