#!/usr/bin/perl

#Created by: MED RAFIK BEN MANSOUR
#Created on: 10/05/2015
#Version No: V1.0

#Change description (if any):

#Purpose: extract userlist from the database (by croning the script or by giving the date range) and save the result in a json file

use strict;
use warnings;

use JSON::XS;
use lib "/appli/bugzilla/bugzilla/lib";  # use the parent directory
use DBI;
use DBD::mysql;
use POSIX qw(strftime);
use strict;
use warnings;
use DateTime;

########################################################################
# JSON Manipulation
########################################################################

#Open the json file in read mode
sub read_json {
        my ($file) = @_;

        local $/; #Enable 'slurp' mode
        open my $fh, "<", "$file";
        my $json = <$fh>;
        close $fh;
        return $json
}

#Open the json file in write mode and append data
sub write_json {
        my ($json, $file, $header, @newData) = @_;

        local $/; #Enable 'slurp' mode
        open my $fh, ">", "$file";
        my $data = decode_json($json);
        push @{ $data->{$header} }, @newData;
        print $fh encode_json($data);
        close $fh;
}

#########################################################################################
#DB Manipulation
##########################################################################################

#single DB connection instance
sub db_connect {
        my($platform, $database, $host, $port, $user, $pw, $socket, $dbh) = @_;
        return $dbh if defined $dbh;
        my $dsn = "dbi:$platform:$database:$host:$port;$socket";
        $dbh = DBI->connect($dsn, $user, $pw);
        return $dbh;
}

#transform the collected datas to json array
sub query_to_json{
        my ($date_array, $dbh, $count_enabled_users, $count_all_users, @users) = @_;
        my @date_array = @{$date_array};
        my @date = ();
        my @json_array = ();

        my $user_nb_per_day;
        for my $i (0 .. $#date_array) {
                $user_nb_per_day = 0;
                my $x = ", ";
                my @c = $users[$i] =~ /$x/g;
                my $user_nb_per_day = @c;
                if($users[$i] ne "") {
                        $user_nb_per_day = $user_nb_per_day+1;
                }
                @date = split /-/, $date_array[$i];
                my $data = {year=>$date[0],month=>$date[1],day=>$date[2], number=>$user_nb_per_day, users=>"$users[$i]", all_users=>$count_all_users, enabled_users=>$count_enabled_users};
                push @json_array, $data;
        }
        return @json_array;
}

#get the users connection per day
sub get_users {
        my ($dbh, $using_activity, @date_array) = @_;
        my @users = ();
        my $sql;
        my $sth;
        my @result = ();
        for my $i (0 .. $#date_array)
        {
                @users = ();
                if($using_activity == 1) {
                        #$sql = qq{select distinct(login_name) as ''  from bugs_activity,profiles where bug_when like "$date_array[$i]%"  and userid=who};
                        $sql = qq{
                                SELECT DISTINCT(login_name)
                                FROM profiles
                                WHERE profiles.userid IN
                                (
                                    SELECT DISTINCT(who)
                                    FROM longdescs
                                     WHERE bug_when BETWEEN "$date_array[$i] 00:00:00" AND "$date_array[$i] 23:59:59"

                                UNION DISTINCT

                                SELECT DISTINCT(who)
                                FROM bugs_activity
                                WHERE bug_when BETWEEN '$date_array[$i] 00:00:00' AND '$date_array[$i] 23:59:59'
                                )
                                ORDER BY login_name
                                };
                } else {
                        $sql = qq{
                                SELECT DISTINCT(login_name)
                                FROM profiles
                                WHERE last_seen_date BETWEEN "$date_array[$i] 00:00:00" AND "$date_array[$i] 23:59:59"
                                };
                        #$sql = qq{select distinct(login_name) as ''  from bugs_activity,profiles where bug_when like "$date_array[$i]%"  and userid=who};
                }
                $sth= $dbh->prepare($sql);
                $sth->execute();

                while (my @data = $sth->fetchrow_array()) {
                        push @users, $data[0];
                }
                my $users_concat =  join(', ',  @users);

                push @result, $users_concat;
        }
        return @result;
}

#get bugzilla user number
sub count_users{
        my ($enabled_users, $dbh) = @_;
        my $sql;
        my $count = 0;
        if($enabled_users == 1) {
                $sql = qq{select count(userid) as "" from profiles Where profiles.login_name NOT LIKE "%.deleted" and is_enabled = "1"};
        } else {
                $sql = qq{select count(userid) as "" from profiles};
        }
        my $sth= $dbh->prepare($sql);
        $sth->execute();

        while (my @data = $sth->fetchrow_array()) {
                $count = $data[0];
        }
        return $count;
}

# create file if it does not exist
sub create_dir{
        my ($dir) = @_;
        mkdir $dir unless -d $dir; # Check if dir exists. If not create it.
}

#Reinit the given file with the given header
sub init_file {
        my ($dir, $filename, $header, $is_log) = @_;
        my $path = "$dir/$filename";
        if (!-e $path || $is_log == 1) {
                local $/;
                open my $fh, ">>", $path or die "Can't open '$path'\n";
                if($is_log == 0){
                        print $fh "{\"$header\":[]}";
                }else{
                        print $fh "[$header]: ";
                }
                close $fh;
        }
}

####################################################################
# Date manipulation
######################################################################
# extract a range from given start and end date (used by the user in the interface)
sub data_from_pool{
        my ($start_date, $end_date) = @_;

        my @date_array = ();
        my @start_date = split /-/, $start_date;
        my @end_date = split /-/, $end_date;

        my $start = DateTime->new(
                        year   => $start_date[0],
                        month => $start_date[1],
                        day  => $start_date[2],
                        );

        my $end = DateTime->new(
                        year   => $end_date[0],
                        month => $end_date[1],
                        day  => $end_date[2],
                        );

        do {
                push @date_array, $start->ymd('-');
        }while ( $start->add(days => 1) <= $end );
        return @date_array;
}
# extract the days from given month-year (used by a monthly cron)
sub month_days{
        my ($year, $month) = @_;

        my @date_array = ();
        my $date = DateTime->new(
                        year  =>  $year,
                        month => $month,
                        day   => 1,
                        );

        my $date2 = $date->clone;

        $date2->add( months => 1 )->subtract( days => 1 );

        push @date_array, $date->ymd('-');
        push @date_array, $date2->ymd('-');
        return @date_array;
}

sub construct_json {
        my($dbh, $using_activity, $count_enabled_users, $count_all_users, $header, $json_file, $log_file, $json_dir, $log_dir, @date_array) = @_;

        my @users = get_users($dbh, $using_activity, @date_array);
        my @json_array =  query_to_json(\@date_array, $dbh, $count_enabled_users, $count_all_users, @users);
        init_file($json_dir, $json_file, $header, 0);
        my $json = read_json("$json_dir/$json_file");
        write_json($json, "$json_dir/$json_file", $header, @json_array);
}

########################################################################
# Main
########################################################################
# connection instance
my $dbh = undef;

# CONFIG VARIABLES
my $platform = "mysql";
my $database = "intbugs";
my $host = "bugzillaqadb.st.com";
my $port = "3308";
my $user = "intbugsadm";
my $pw = "0/admin";
my $socket = "";

#dirs
my $log_dir = "logs";
my $json_dir = "user_monitor/json";

#log file
my $log_file = "stats_log.log";
#first json
my $header_activity = "stats";
my $json_file_activity = "data_activity.json";
#second json
my $header_cnx = "stats";
my $json_file_cnx = "data_cnx.json";

my @date_array = ();

my $num_args = $#ARGV + 1;

if ($num_args == 1 &&  $ARGV[0] eq "cron"){
        my $current = strftime "%Y-%m-%d", localtime;
        $date_array[0] = ($current);
        $dbh = db_connect($platform, $database, $host, $port, $user, $pw, $socket, $dbh);

        #count users
        my $count_enabled_users = count_users(1, $dbh);
        my $count_all_users = count_users(0, $dbh);

        #init directories and log file
        create_dir($json_dir);
        create_dir($log_dir);
        my $current_date = strftime "%d-%m-%Y", localtime;
        init_file($log_dir, $log_file, $current_date, 1);

        #create activity json file
        construct_json($dbh, 1, $count_enabled_users, $count_all_users, $header_activity, $json_file_activity, $log_file, $json_dir, $log_dir, @date_array);
        #create cnx json file
        construct_json($dbh, 0, $count_enabled_users, $count_all_users, $header_cnx, $json_file_cnx, $log_file, $json_dir, $log_dir, @date_array);
}
elsif ($num_args == 2) {

        my $start_date = $ARGV[0];
        my $end_date = $ARGV[1];
        @date_array = data_from_pool($start_date, $end_date);

        $dbh = db_connect($platform, $database, $host, $port, $user, $pw, $socket,$dbh);

        #count users
        my $count_enabled_users = count_users(1, $dbh);
        my $count_all_users = count_users(0, $dbh);

        #init directories and log file
        create_dir($json_dir);
        create_dir($log_dir);
        my $current_date = strftime "%d-%m-%Y", localtime;
        init_file($log_dir, $log_file, $current_date, 1);

        #create activity json file
        construct_json($dbh, 1, $count_enabled_users, $count_all_users, $header_activity, $json_file_activity, $log_file, $json_dir, $log_dir, @date_array);
        #create cnx json file
        construct_json($dbh, 0, $count_enabled_users, $count_all_users, $header_cnx, $json_file_cnx, $log_file, $json_dir, $log_dir, @date_array);
}
else {
        print"\nUsage :\t$0 YYYY-MM-DD YYYY-MM-DD\n\nor simply  cron it (daily) to get the exact daily results\nUsage :\t$0 cron\n\n";
}
print "OK\n";

