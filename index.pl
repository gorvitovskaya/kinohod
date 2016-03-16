#!/usr/bin/perl
{
package MyWebServer;
 
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);

use lib::DB;
 
sub handle_request {
    my ($self, $cgi) = @_;

    $self->{dbh} = lib::DB->new();
  
    my $path = $cgi->path_info(); $path =~ s/\///;
    my $calendarExist = $self->{dbh}->select("SELECT count(*) FROM calendars WHERE lnk=?", p=>[$path], field=>1);

    if ($path eq 'main' || $calendarExist) {
    	print "HTTP/1.0 200 OK\r\n";
    	my $mod = ($path eq 'main') ? 'main' : 'calendar'; $mod = 'mods::'.$mod;
    	eval "use ".$mod.";";
    	if($@) {$self->errorPage($cgi, $@);}
    	else {
    		my ($title, $html, $noCgi) = $mod->new(dbh=>$self->{dbh}, calendar=>($path ne 'main')?$path:undef);
    		if($noCgi){ 
    			print "Content-type:text/html\n\n";
    			print '<script src="/inc/js/site.js" type="text/javascript"></script>';
    			print $html;
    		}
    		else{
    			print $cgi->header(-charset => 'UTF-8'),
    			$cgi->start_html(
		       		-title      => $title,
		       		-style      => [
		       			{'src'=>'/inc/css/jquery-ui.min.css'},
		       			{'src'=>'/inc/css/style.css'},
		       		],
		       		-script 	=> [
			            {-type => 'javascript', -src  => '/inc/js/jquery-1.12.1.min.js'},
			            {-type => 'javascript', -src  => '/inc/js/jquery-ui.min.js'},
			            {-type => 'javascript', -src  => '/inc/js/site.js'},
			            {-type => 'javascript', -src  => '/inc/js/jquery.form.js'},
			        ]
		       	),
		       	$cgi->p($html),
		       	$cgi->end_html;	
    		}	
    	}
    }
    elsif( -f $path ){
    	print "HTTP/1.0 200 OK\r\n";
    	if($path =~ /\.css$/){
    		print "Content-type:text/css\n\n";
    	} elsif($path =~ /\.js$/){
    		print "Content-type:text/javascript\n\n";
    	} else {
    		print "Content-type:text/html\n\n";	
    	}
    	
    	open FILE, '<'.$path;
    	print <FILE>;
    	close FILE;
    }
    else {$self->notFoundPage($cgi);}
}

sub errorPage {
	my ($self, $cgi, $err) = @_;
	return if !ref $cgi;

	print $cgi->header,
       	$cgi->start_html,
       	$cgi->p($err),
       	$cgi->end_html;
}

sub notFoundPage {
	my ($self, $cgi) = @_;
	return if !ref $cgi;

	print "HTTP/1.0 404 Not found\r\n";
	print $cgi->header,
       	$cgi->start_html('Not found'),
       	$cgi->h1('Not found'),
       	$cgi->end_html;
}
 
} 
 
my $pid = MyWebServer->new(8080)->background();
print "Use 'kill $pid' to stop server.\n";


1;