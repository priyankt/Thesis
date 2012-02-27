package PacketData;

sub new {
    my ($class, $data) = @_;
    my $self = {
	packet_number => 0,
	index => 0,
	data => $data,
	total_bytes => 0,
    };
    bless $self, $class;
    return $self;
}

sub process_data {
    my ($self, $req_type) = @_;

    if($req_type eq 'begin') {
	# ignore first 13 bytes of signature and zero previous size present in begin
        # and start reading tags
	$self->get_bytes(13);
    }
    
    while(1) {

	my $tag_content = $self->get_bytes(11);
	last if($tag_content eq '');

	my $tag = $self->parse_tag_content($tag_content);

        # skip tag data
	my $data_content = $self->get_bytes($tag->{datasize});
	last if($data_content eq '');

	my $sys_time = $self->current_packet_system_time();
	my $key = $self->get_current_packet_key();
	my $id = $self->get_youtube_id();
	my $total_bytes = $self->get_total_bytes();

	print "$sys_time, $tag->{type}, $tag->{timestamp}, $tag->{datasize}, $total_bytes, $key, $id\n";
	#$self->set_data_size($self->get_data_size()+$tag->{datasize});

        # skip previous tag size
	my $prev_size = $self->get_bytes(4);
	last if($prev_size eq '');
    }
}

sub set_total_bytes {
    my ($self, $value) = @_;
    $self->{total_bytes} = $value;
}

sub get_total_bytes {
    my $self = shift;
    return $self->{total_bytes};
}

sub get_youtube_id {
    my $self = shift;
    my $packet_num = $self->get_packet_number();
    return $self->{data}->[$packet_num]->{id};
}

sub parse_tag_content {
    my ($self, $content) = @_;

   my ($type, @datasize, @timestamp);
   (
      $type,         $datasize[0],  $datasize[1],  $datasize[2],
      $timestamp[1], $timestamp[2], $timestamp[3], $timestamp[0]
   ) = unpack 'CCCCCCCC', $content;

   my $datasize = ($datasize[0] * 256 + $datasize[1]) * 256 + $datasize[2];
   my $timestamp
       = (($timestamp[0] * 256 + $timestamp[1]) * 256 + $timestamp[2]) * 256 +
       $timestamp[3];

   if ($timestamp > 4_000_000_000 || $timestamp < 0)
   {
      warn "Funny timestamp: @timestamp -> $timestamp\n";
   }

   if ($datasize < 11)
   {
      #die "Tag size is too small ($datasize) at byte " . $file->get_pos(-10);
      warn "Tag size is too small ($datasize)";
   }

   return { timestamp=>$timestamp, datasize=>$datasize, type=>$type };
}

sub get_bytes {
    my ($self, $num_bytes_to_read) = @_;

    my $num_bytes = $num_bytes_to_read;

    my $content = '';
    while(1) {
	#print STDERR $num_bytes . ',' . $self->get_packet_number() . ',' . $self->index() . ',' . $self->current_packet_length() . ',' . $self->current_packet_system_time() . ',' . $self->{data}->[$self->get_packet_number()]->{idd} . "\n";
	if( $num_bytes <= $self->current_packet_length()-$self->index() ) {
	    $content .= substr $self->get_packet_data(), $self->index(), $num_bytes;
	    $self->set_index($self->index()+$num_bytes);
	    last;
	}
	else {
	    $content .= substr $self->get_packet_data(), $self->index(), $self->current_packet_length()-$self->index();
	    $num_bytes -= ($self->current_packet_length() - $self->index());

            # TO DO: handle max packet count error here
	    my $ret_val = $self->incr_packet_count();
	    if($ret_val == -1) {
		$content = '';
		last;
	    }
	    $self->set_index(0);
	}
    }
    $self->set_total_bytes($self->get_total_bytes()+$num_bytes_to_read);

    return $content;
}

sub get_current_packet_key {
    my $self = shift;
    my $packet_num = $self->get_packet_number();
    return $self->{data}->[$packet_num]->{key};
}

sub incr_packet_count {
    my $self = shift;

    if($self->get_packet_number() + 1 < $self->total_packets()) {
	$self->{packet_number} += 1;
    }
    else {
	die "Max packet number reached - $self->{packet_number} - " . $self->total_packets() . "\n";
    }
}

sub current_packet_system_time {
    my $self = shift;
    
    my $packet_num = $self->get_packet_number();
    return $self->{data}->[$packet_num]->{time};
}

sub total_packets {
    my $self = shift;
    return scalar( @{$self->{data}} );
}

sub set_index {
    my ($self, $n) = @_;
    $self->{index} = $n;
}

sub get_packet_data {
    my $self = shift;
    my $packet_num = $self->get_packet_number();
    return $self->{data}->[$packet_num]->{content};
}

sub index {
    my $self = shift;
    return $self->{index};
}

sub current_packet_length {
    my $self = shift;
    my $packet_num = $self->get_packet_number();
    return length($self->{data}->[$packet_num]->{content});
}

sub get_packet_number {
    my $self = shift;
    return $self->{packet_number};
}

1;
