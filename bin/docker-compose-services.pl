#!/usr/bin/env perl 
use strict;
use warnings;

use utf8;

=encoding UTF8

=head1 NAME

docker-compose-services.pl - Script to generate docker-compose file for stats and metrics services.

=head1 SYNOPSIS

Generate docker-compose.yml file.
Example
    bin/docker-compose-services.pl -e production


=head1 DESCRIPTION

This script is to generate the needed docker-compose.yml file based on a config file.
It generate all the needed containers for metrics collection, aggregatig, and visulizig.
This includes Prometheus, Grafana, and multiple exporters.
It also accepts custom exporters list for services available in environment.

=cut

=head1 OPTIONS

=over 4

=item B<-b> I</app/>, B<--base-path>=I<./>

Base path where tools directory located.
Default is current path: ./

=item B<-e> I<dev>, B<--environment>=I<production>

Select which environment to generate configuration for.
Default is set to: dev

=item B<-o> I<./docker-compose.yml>, B<--output-file>=I<path>

Path of file to write docker-compose.yml.
Default: ./docker-compose.yml

=item B<-l> I<debug>, B<--log-level>=I<info>

Log level for script.
Default is: info

=back

=cut

use Template;
use Pod::Usage;
use Getopt::Long;
use Syntax::Keyword::Try;
use YAML::XS qw(LoadFile);
use Log::Any qw($log);
use Path::Tiny;
use JSON::MaybeUTF8 qw(:v1);
use Sys::Hostname;

GetOptions(
    'b|base-path=s'      => \(my $base_path      = './'),
    'c|config-file=s'    => \(my $config_path = './config.yml'),
    'e|environment=s'    => \(my $env            = 'dev'),
    'o|output-file=s'    => \(my $output_file),
    'l|log-level=s'      => \(my $log_level      = 'info'),
    'h|help'             => \my $help,
);

require Log::Any::Adapter;
Log::Any::Adapter->set( qw(Stdout), log_level => $log_level );

pod2usage(
    {
        -verbose  => 99,
        -sections => "NAME|SYNOPSIS|DESCRIPTION|OPTIONS",
    }
) if $help;


my $config = {};
my $server;

=head1 METHODS

=cut

my @services;

use Data::Dumper;
$log->infof('Before genrate | %s | %s', Dumper($config), encode_json_text($config));

my $tt = Template->new;
$tt->process(
    'docker-compose.yml.tt2',
    {
        pg_count     => $ENV{PG_COUNT} // 2,
        redis_count  => $ENV{REDIS_COUNT} // 6,
        incl_stats   => $ENV{INCL_STATS} // 1,
        service_list => \@services,
    },
    'docker-compose.yml'
) or die $tt->error;

$log->info('DONE');
