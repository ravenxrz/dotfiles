set print sevenbit off
set print elements 0
set print pretty on
handle SIGUSR1 nostop noprint
handle SIGUSR2 nostop noprint
handle SIGWAITING nostop noprint
handle SIGLWP nostop noprint
handle SIGPIPE nostop noprint
handle SIGALRM nostop noprint
handle SIGHUP nostop noprint
handle SIG40 nostop noprint
handle SIGTERM nostop noprint

define mach_read_from_1
  set $c0=*(unsigned char*)((char*)$arg0)
  printf "%u\n", ((unsigned short)$c0)
end

define hex_read_from_1
  set $c0=*(unsigned char*)((char*)$arg0)
  printf "%02X\n", $c0
end

define mach_read_from_2
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  printf "%u\n", ((unsigned short)$c0 << 8) + ((unsigned short)$c1)
end

define mach_read_from_3
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  printf "%u\n", ((unsigned int)$c0 << 16) + ((unsigned int)$c1 << 8) + ((unsigned int)$c2)
end

define hex_read_from_3
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  printf "%02X %02X %02X\n", $c0, $c1, $c2
end

define hex_read_from_2
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  printf "%02X %02X\n", $c0, $c1
end

define mach_read_from_4
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  set $c3=*(unsigned char*)((char*)$arg0+3)
  printf "%u\n", ((unsigned int)$c0 << 24) + ((unsigned int)$c1 << 16) + ((unsigned int)$c2 << 8) + ((unsigned int)$c3)
end

define mach_parse_compressed
  set $c0=*(unsigned char*)((char*)$arg0)
  set $val=((unsigned long int)$c0)
  if $val < 0x80
    printf "%u +1\n", $val
    set $val=0xFF
  end
  if $val < 0xC0
    set $c1=*(unsigned char*)((char*)$arg0+1)
    set $val=((unsigned long int)$c0 << 8) + ((unsigned long int)$c1)
    set $val=($val & 0x3FFF)
    printf "%u +2\n", $val
    set $val=0xFF
  end
  if $val < 0xE0
    set $c1=*(unsigned char*)((char*)$arg0+1)
    set $c2=*(unsigned char*)((char*)$arg0+2)
    set $val=((unsigned long int)$c0 << 16) + ((unsigned long int)$c1 << 8) + ((unsigned long int)$c2)
    set $val=($val & 0x1FFFFF)
    printf "%u +3\n", $val
    set $val=0xFF
  end
  if $val < 0xF0
    set $c1=*(unsigned char*)((char*)$arg0+1)
    set $c2=*(unsigned char*)((char*)$arg0+2)
    set $c3=*(unsigned char*)((char*)$arg0+3)
    set $val=((unsigned long int)$c0 << 24) + ((unsigned long int)$c1 << 16) + ((unsigned long int)$c2 << 8) + ((unsigned long int)$c3)
    set $val=($val & 0xFFFFFFF)
    printf "%u +4\n", $val
    set $val=0xFF
  end
  if $val == 0xF0
    set $c0=*(unsigned char*)((char*)$arg0+1)
    set $c1=*(unsigned char*)((char*)$arg0+2)
    set $c2=*(unsigned char*)((char*)$arg0+3)
    set $c3=*(unsigned char*)((char*)$arg0+4)
    set $val=((unsigned long int)$c0 << 24) + ((unsigned long int)$c1 << 16) + ((unsigned long int)$c2 << 8) + ((unsigned long int)$c3)
    set $ptr=$arg0+5
    printf "%u +5\n", $val
  end
end

define hex_read_from_4
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  set $c3=*(unsigned char*)((char*)$arg0+3)
  printf "%02X %02X %02X %02X\n", $c0, $c1, $c2, $c3
end

define mach_read_from_6
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  set $c3=*(unsigned char*)((char*)$arg0+3)
  set $c4=*(unsigned char*)((char*)$arg0+4)
  set $c5=*(unsigned char*)((char*)$arg0+5)
  printf "%lu\n", ((unsigned long long)$c0 << 40) + ((unsigned long long)$c1 << 32) + ((unsigned long long)$c2 << 24) + ((unsigned long long)$c3 << 16) + ((unsigned long long)$c4 << 8) + ((unsigned long long)$c5)
end

define mach_read_from_8
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  set $c3=*(unsigned char*)((char*)$arg0+3)
  set $c4=*(unsigned char*)((char*)$arg0+4)
  set $c5=*(unsigned char*)((char*)$arg0+5)
  set $c6=*(unsigned char*)((char*)$arg0+6)
  set $c7=*(unsigned char*)((char*)$arg0+7)
  printf "%lu\n", ((unsigned long long)$c0 << 56) + ((unsigned long long)$c1 << 48) + ((unsigned long long)$c2 << 40) + ((unsigned long long)$c3 << 32) + ((unsigned long long)$c4 << 24) + ((unsigned long long)$c5 << 16) + ((unsigned long long)$c6 << 8) + ((unsigned long long)$c7)
end

define hex_read_from_8
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  set $c3=*(unsigned char*)((char*)$arg0+3)
  set $c4=*(unsigned char*)((char*)$arg0+4)
  set $c5=*(unsigned char*)((char*)$arg0+5)
  set $c6=*(unsigned char*)((char*)$arg0+6)
  set $c7=*(unsigned char*)((char*)$arg0+7)
  printf "%02X %02X %02X %02X %02X %02X %02X %02X\n", $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7
end

define hex_read_from_n
  set $j=0
  set $ptr=(unsigned char*)$arg0
  set $max=$arg1
  while $j<$max
    set $c=*($ptr+$j)
    printf "%02X ", $c
    set $j++
  end
  printf "\n"
end

define mach_read_from_n_little_endian
  set $i=0
  set $buf=(unsigned char*)$arg0
  set $buf_size=$arg1
  set $ptr=$buf+$buf_size
  set $n=0
  while (1)
    set $ptr=$ptr-1
    set $n=($n << 8)
    set $n=$n+(unsigned long)(*(unsigned char*)((char*)$ptr))
    if $ptr == $buf
      loop_break
    end
  end
  printf "%lu\n", $n
end

define trx_undo_decode_roll_ptr
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  set $c3=*(unsigned char*)((char*)$arg0+3)
  set $c4=*(unsigned char*)((char*)$arg0+4)
  set $c5=*(unsigned char*)((char*)$arg0+5)
  set $c6=*(unsigned char*)((char*)$arg0+6)
  set $roll_ptr=((unsigned long long)$c0 << 48) + ((unsigned long long)$c1 << 40) + ((unsigned long long)$c2 << 32) + ((unsigned long long)$c3 << 24) + ((unsigned long long)$c4 << 16) + ((unsigned long long)$c5 << 8) + ((unsigned long long)$c6)
  set $offset=($roll_ptr & 0xFFFF)
  set $roll_ptr=($roll_ptr >> 16)
  set $page_no=($roll_ptr & 0xFFFFFFFF)
  set $roll_ptr=($roll_ptr >> 32)
  set $rseg_id=($roll_ptr & 0x7F)
  set $roll_ptr=($roll_ptr >> 7)
  printf "offset: %u\n", $offset
  printf "page_no: %u\n", $page_no
  printf "rseg_id: %u\n", $rseg_id
  if $roll_ptr == 0
    printf "is_insert: FALSE\n"
  else
    printf "is_insert: TRUE\n"
  end
end

define mysql_print_fil_header
  set $page=(char*)$arg0

  set $fil_page_checksum=$page
  printf "FIL_PAGE_CHECKSUM: "
  hex_read_from_4 $fil_page_checksum

  set $fil_page_offset=$fil_page_checksum+4
  printf "FIL_PAGE_OFFSET: "
  mach_read_from_4 $fil_page_offset

  set $fil_page_prev=$fil_page_offset+4
  printf "FIL_PAGE_PREV: "
  mach_read_from_4 $fil_page_prev

  set $fil_page_next=$fil_page_prev+4
  printf "FIL_PAGE_NEXT: "
  mach_read_from_4 $fil_page_next

  set $fil_page_lsn=$fil_page_next+4
  printf "FIL_PAGE_LSN: "
  mach_read_from_8 $fil_page_lsn

  # File page types (values of FIL_PAGE_TYPE)
  # - FIL_PAGE_INDEX        17855    /*!< B-tree node */
  # - FIL_PAGE_RTREE        17854    /*!< B-tree node */
  # - FIL_PAGE_UNDO_LOG    2    /*!< Undo log page */
  # - FIL_PAGE_INODE        3    /*!< Index node */
  # - FIL_PAGE_IBUF_FREE_LIST    4    /*!< Insert buffer free list */
  # File page types introduced in MySQL/InnoDB 5.1.7
  # - FIL_PAGE_TYPE_ALLOCATED    0    /*!< Freshly allocated page */
  # - FIL_PAGE_IBUF_BITMAP    5    /*!< Insert buffer bitmap */
  # - FIL_PAGE_TYPE_SYS    6    /*!< System page */
  # - FIL_PAGE_TYPE_TRX_SYS    7    /*!< Transaction system data */
  # - FIL_PAGE_TYPE_FSP_HDR    8    /*!< File space header */
  # - FIL_PAGE_TYPE_XDES    9    /*!< Extent descriptor page */
  # - FIL_PAGE_TYPE_BLOB    10    /*!< Uncompressed BLOB page */
  # - FIL_PAGE_TYPE_ZBLOB    11    /*!< First compressed BLOB page */
  # - FIL_PAGE_TYPE_ZBLOB2    12    /*!< Subsequent compressed BLOB page */
  # - FIL_PAGE_TYPE_UNKNOWN    13    /*!< In old tablespaces, garbage in FIL_PAGE_TYPE is replaced with this value when flushing pages. */
  # - FIL_PAGE_COMPRESSED    14    /*!< Compressed page */
  # - FIL_PAGE_ENCRYPTED    15    /*!< Encrypted page */
  # - FIL_PAGE_COMPRESSED_AND_ENCRYPTED 16  /*!< Compressed and Encrypted page */
  # - FIL_PAGE_ENCRYPTED_RTREE 17    /*!< Encrypted R-tree page */
  set $fil_page_type=$fil_page_lsn+8
  printf "FIL_PAGE_TYPE: "
  mach_read_from_2 $fil_page_type

  set $fil_page_file_flush_lsn=$fil_page_type+2
  printf "FIL_PAGE_FILE_FLUSH_LSN: "
  mach_read_from_8 $fil_page_file_flush_lsn

  set $fil_page_space_id=$fil_page_file_flush_lsn+8
  printf "FIL_PAGE_SPACE_ID: "
  mach_read_from_4 $fil_page_space_id
end

define mysql_print_page_header
  set $page=(char*)$arg0

  set $page_n_dir_slots=$page+38
  printf "PAGE_N_DIR_SLOTS: "
  mach_read_from_2 $page_n_dir_slots

  set $page_heap_top=$page_n_dir_slots+2
  printf "PAGE_HEAP_TOP: "
  mach_read_from_2 $page_heap_top

  set $page_n_heap=$page_heap_top+2
  printf "PAGE_N_HEAP: "
  hex_read_from_2 $page_n_heap

  set $page_free=$page_n_heap+2
  printf "PAGE_FREE: "
  mach_read_from_2 $page_free

  set $page_garbage=$page_free+2
  printf "PAGE_GARBAGE: "
  mach_read_from_2 $page_garbage

  set $page_last_insert=$page_garbage+2
  printf "PAGE_LAST_INSERT: "
  mach_read_from_2 $page_last_insert

  set $page_direction=$page_last_insert+2
  printf "PAGE_DIRECTION: "
  mach_read_from_2 $page_direction

  set $page_n_direction=$page_direction+2
  printf "PAGE_N_DIRECTION: "
  mach_read_from_2 $page_n_direction

  set $page_n_recs=$page_n_direction+2
  printf "PAGE_N_RECS: "
  mach_read_from_2 $page_n_recs

  set $page_max_trx_id=$page_n_recs+2
  printf "PAGE_MAX_TRX_ID: "
  hex_read_from_8 $page_max_trx_id

  set $page_level=$page_max_trx_id+8
  printf "PAGE_LEVEL: "
  mach_read_from_2 $page_level

  set $page_index_id=$page_level+2
  printf "PAGE_INDEX_ID: "
  hex_read_from_8 $page_index_id
end

define mysql_ut_align
  set $ptr=(char*)$arg0
  set $addr=(char*)((((unsigned long long int)$ptr)+16384-1)&~(16384-1))
  printf "Aligned address: %p\n", $addr
end

define mysql_page_align
  set $ptr=(char*)$arg0
  set $page=(char*)(((unsigned long long int)$ptr)&~(16384-1))
  printf "Page address: %p\n", $page
end

define mysql_page_offset
  set $ptr=(char*)$arg0
  set $offset=(((unsigned long long int)$ptr)&(16384-1))
  printf "Record offset: %lu\n", $offset
end

define mysql_print_comp_rec
  set $ptr=(char*)$arg0
  set $base_offset=(((unsigned long long int)$ptr)&(16384-1))

  printf "\tOFFSET: "
  printf "%u\n", $base_offset
  printf "\tNULL BITS: "
  hex_read_from_1 ($ptr-6)

  set $c0=*(unsigned char*)($ptr-5)
  set $info_bits=((unsigned short)$c0)
  printf "\tINFO BITS (?|?|DELETED|MIN_REC): "
  printf "%01X\n", ($info_bits >> 4)
  printf "\tN_OWNED: "
  printf "%u\n", ($info_bits & 15)

  set $c0=*(unsigned char*)($ptr-4)
  set $c1=*(unsigned char*)($ptr-3)
  set $rec_info=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  printf "\tHEAP_NO: "
  printf "%u\n", ($rec_info >> 3)
  printf "\tREC STATUS: "
  set $rec_type = ($rec_info & 7)
  if $rec_type == 0
    printf "000-REC_STATUS_ORDINARY\n"
  end
  if $rec_type == 1
    printf "001-REC_STATUS_NODE_PTR\n"
  end
  if $rec_type == 2
    printf "010-REC_STATUS_INFIMUM\n"
  end
  if $rec_type == 3
    printf "011-REC_STATUS_SUPREMUM\n"
  end
  if $rec_type > 3
    printf "1xx-Reserved\n"
  end

  printf "\tNEXT OFFSET: "
  set $c0=*(unsigned char*)($ptr-2)
  set $c1=*(unsigned char*)($ptr-1)
  set $next_incr_offset=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  if ($base_offset + $next_incr_offset) > 16384
    printf "%u\n", (($base_offset + $next_incr_offset) % 16384)
  else
    printf "%u\n", ($base_offset + $next_incr_offset)
  end

  if $rec_type <= 1
    printf "\tRest of the comp record: "
    if ($base_offset + $next_incr_offset) < 16384
      if $next_incr_offset <= 70
        hex_read_from_n $ptr ($next_incr_offset-6)
      else
        hex_read_from_n $ptr 64
      end
    else
      printf "N/A\n"
    end
  end
end

define mysql_print_user_records
  set $page=(char*)$arg0

  set $c0=*(unsigned char*)((char*)$page+42)
  set $c1=*(unsigned char*)((char*)$page+43)
  set $page_n_heap=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  set $page_data_offset=38+36+2*10
  if (($page_n_heap & 0x8000)==0x8000)
    # the page is in new-style compact format
    # (PAGE_DATA + REC_N_NEW_EXTRA_BYTES)
    printf "The page is in new-style compact format\n"
    set $infimum=$page_data_offset+5
    # (PAGE_DATA + 2 * REC_N_NEW_EXTRA_BYTES + 8)
    set $supremum=$page_data_offset+2*5+8

    set $c0=*(unsigned char*)((char*)$page+$infimum-2)
    set $c1=*(unsigned char*)((char*)$page+$infimum-1)
    set $record_extra_bytes=5
    set $offset=$infimum+((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  else
    # the page is in old-style redundant format
    # (PAGE_DATA + 1 + REC_N_OLD_EXTRA_BYTES)
    printf "The page is in old-style redundant format\n"
    set $infimum=$page_data_offset+1+6
    # (PAGE_DATA + 2 + 2 * REC_N_OLD_EXTRA_BYTES + 8)
    set $supremum=$page_data_offset+2+2*6+8

    set $c0=*(unsigned char*)((char*)$page+$infimum-2)
    set $c1=*(unsigned char*)((char*)$page+$infimum-1)
    set $offset=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
    set $record_extra_bytes=6
  end

  set $c0=*(unsigned char*)((char*)$page+54)
  set $c1=*(unsigned char*)((char*)$page+55)
  set $expected_records_inheader=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  printf "Expected records in header: %u\n", $expected_records_inheader
  printf "OFFSET OF INFIMUM: %u\n", $infimum
  if (($page_n_heap & 0x8000)==0x8000)
    mysql_print_comp_rec ((char*)$page+$infimum)
  end
  printf "OFFSET OF SUPREMUM: %u\n", $supremum
  if (($page_n_heap & 0x8000)==0x8000)
    mysql_print_comp_rec ((char*)$page+$supremum)
  end

  set pagination off
  set $i=0
  while (($offset < 16384-$record_extra_bytes) && ($offset != $supremum))
    printf "OFFSET OF REC #%u: %u\n", $i, $offset
    set $c0=*(unsigned char*)((char*)$page+$offset-2)
    set $c1=*(unsigned char*)((char*)$page+$offset-1)
    if (($page_n_heap & 0x8000)==0x8000)
      mysql_print_comp_rec ((char*)$page+$offset)
      set $incr_offset=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
      if ($incr_offset==0)
        printf "***FATAL ERROR DURING PARSING***\n"
        loop_break
      end
      set $offset=$offset+$incr_offset
    else
      set $next_offset=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
      if (($next_offset==0) || ($next_offset==$offset))
        printf "***FATAL ERROR DURING PARSING***\n"
        loop_break
      end
      set $offset=$next_offset
    end
    if $offset > 16384
      set $offset=($offset % 16384)
    end
    set $i++
  end
  set pagination on
end

define mysql_print_page_directory
  set $page=(char*)$arg0

  set pagination off
  set $c0=*(unsigned char*)((char*)$page+38)
  set $c1=*(unsigned char*)((char*)$page+39)
  set $page_n_dir_slots=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  set $i=0
  while $i<$page_n_dir_slots
    set $slot=$page+16384-10-$i*2
    printf "OFFSET OF SLOT #%d: ", $i
    mach_read_from_2 $slot
    set $i++
  end
  set pagination on
end

define mysql_print_fil_tailer
  set $page=(char*)$arg0

  set $fil_tailer=$page+16384-8
  printf "FIL_PAGE_END_LSN_OLD_CHKSUM: "
  hex_read_from_8 $fil_tailer
end

define mysql_print_undo_log_segment
  set $page=(char*)$arg0

  set $trx_undo_page_type=$page+38
  printf "TRX_UNDO_PAGE_TYPE: "
  mach_read_from_2 $trx_undo_page_type

  set $trx_undo_page_start=$trx_undo_page_type+2
  printf "TRX_UNDO_PAGE_START: "
  mach_read_from_2 $trx_undo_page_start

  set $trx_undo_page_free=$trx_undo_page_start+2
  printf "TRX_UNDO_PAGE_FREE: "
  mach_read_from_2 $trx_undo_page_free
end

define mysql_print_page
  set $page=(char*)$arg0

  set logging overwrite on
  set logging file mysql_page_all.txt
  set logging on

  mysql_print_fil_header $page
  set $c0=*(unsigned char*)((char*)$page+24)
  set $c1=*(unsigned char*)((char*)$page+25)
  set $page_type=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  # FIL_PAGE_INDEX
  if $page_type == 17855
    mysql_print_page_header $page
    mysql_print_user_records $page
    mysql_print_page_directory $page
  end
  # FIL_PAGE_UNDO_LOG
  if $page_type == 2
    mysql_print_undo_log_segment $page
  end
  mysql_print_fil_tailer $page

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_freed_comp_rec
  set $ptr=(char*)$arg0
  set $base_offset=(((unsigned long long int)$ptr)&(16384-1))

  printf "\tOFFSET: "
  printf "%u\n", $base_offset
  printf "\tNULL BITS: "
  hex_read_from_1 ($ptr-6)

  set $c0=*(unsigned char*)($ptr-5)
  set $info_bits=((unsigned short)$c0)
  printf "\tINFO BITS (?|?|DELETED|MIN_REC): "
  printf "%01X\n", ($info_bits >> 4)
  printf "\tN_OWNED: "
  printf "%u\n", ($info_bits & 15)

  set $c0=*(unsigned char*)($ptr-4)
  set $c1=*(unsigned char*)($ptr-3)
  set $rec_info=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  printf "\tHEAP_NO: "
  printf "%u\n", ($rec_info >> 3)
  printf "\tREC STATUS: "
  set $rec_type = ($rec_info & 7)
  if $rec_type == 0
    printf "000-REC_STATUS_ORDINARY\n"
  end
  if $rec_type == 1
    printf "001-REC_STATUS_NODE_PTR\n"
  end
  if $rec_type == 2
    printf "010-REC_STATUS_INFIMUM\n"
  end
  if $rec_type == 3
    printf "011-REC_STATUS_SUPREMUM\n"
  end
  if $rec_type > 3
    printf "1xx-Reserved\n"
  end

  printf "\tNEXT OFFSET: "
  set $c0=*(unsigned char*)($ptr-2)
  set $c1=*(unsigned char*)($ptr-1)
  set $next_incr_offset=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  if ($base_offset + $next_incr_offset) > 16384
    printf "%u\n", (($base_offset + $next_incr_offset) % 16384)
  else
    printf "%u\n", ($base_offset + $next_incr_offset)
  end
end

define mysql_print_freed_records
  set $page=(char*)$arg0

  set logging overwrite on
  set logging file mysql_page_freed.txt
  set logging on

  set $c0=*(unsigned char*)((char*)$page+24)
  set $c1=*(unsigned char*)((char*)$page+25)
  set $page_type=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  # FIL_PAGE_INDEX
  if $page_type == 17855
    set $c0=*(unsigned char*)((char*)$page+42)
    set $c1=*(unsigned char*)((char*)$page+43)
    set $page_n_heap=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
    set $c0=*(unsigned char*)((char*)$page+44)
    set $c1=*(unsigned char*)((char*)$page+45)
    set $page_free=((unsigned short)$c0 << 8) + ((unsigned short)$c1)

    if (($page_n_heap & 0x8000)==0x8000)
      # the page is in new-style compact format
      printf "The page is in new-style compact format\n"
    else
      # the page is in old-style redundant format
      printf "The page is in old-style redundant format\n"
    end

    if ($page_free==0)
      printf "The page does not contain freed records\n"
    else
      set pagination off
      set $offset=$page_free
      set $i=0
      while (1)
        printf "OFFSET OF FREED REC #%u: %u\n", $i, $offset
        set $c0=*(unsigned char*)((char*)$page+$offset-2)
        set $c1=*(unsigned char*)((char*)$page+$offset-1)
        set $last_offset=$offset
        if (($page_n_heap & 0x8000)==0x8000)
          mysql_print_freed_comp_rec ((char*)$page+$offset)
          set $offset=$last_offset+((unsigned short)$c0 << 8) + ((unsigned short)$c1)
        else
          set $offset=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
        end
        if $offset > 16384
          set $offset=($offset % 16384)
        end
        if ($offset==$last_offset)
          loop_break
        end
        set $i++
      end
      set pagination on
    end
  else
    printf "Unsupported page type: %d\n", page_type
  end

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_mlog_comp_rec_insert
  set $ptr=(char*)$arg0
  set $end_ptr=(char*)$arg1

  printf "Number of columns: "
  set $c0=*(unsigned char*)($ptr)
  set $c1=*(unsigned char*)($ptr+1)
  set $n_columns=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  printf "%u\n", $n_columns
  set $ptr=$ptr+2

  printf "Number of unique keys: "
  mach_read_from_2 $ptr
  set $ptr=$ptr+2

  set $i=0
  while $i<$n_columns
    printf "LEN HEX #%d: ", $i
    hex_read_from_2 $ptr
    set $ptr=$ptr+2
    set $i++
  end

  printf "Offset to the prev page record: "
  mach_read_from_2 $ptr
  set $ptr=$ptr+2

  # Refer to mach_parse_compressed function
  set $c0=*(unsigned char*)($ptr)
  set $val=((unsigned short)$c0)
  if $val < 0x80
    printf "Length of the page record: %u\n", ($val >> 1)
    set $ptr=$ptr+1
  end
  printf "Rest of the log record: "
  if $end_ptr > $ptr
    hex_read_from_n $ptr ($end_ptr-$ptr)
  else
    printf "Illegal log record\n"
  end
end

define mysql_print_mlog_comp_rec_delete
  set $ptr=(char*)$arg0
  set $end_ptr=(char*)$arg1

  printf "Number of columns: "
  set $c0=*(unsigned char*)($ptr)
  set $c1=*(unsigned char*)($ptr+1)
  set $n_columns=((unsigned short)$c0 << 8) + ((unsigned short)$c1)
  printf "%u\n", $n_columns
  set $ptr=$ptr+2

  printf "Number of unique keys: "
  mach_read_from_2 $ptr
  set $ptr=$ptr+2

  set $i=0
  while $i<$n_columns
    printf "LEN HEX #%d: ", $i
    hex_read_from_2 $ptr
    set $ptr=$ptr+2
    set $i++
  end

  printf "Offset to the page record: "
  mach_read_from_2 $ptr
  set $ptr=$ptr+2

  if $end_ptr < $ptr
    printf "Illegal log record\n"
  end
end

define mysql_print_recv_t
  set $recv=(recv_t*)$arg0

  printf "Log record body length: "
  printf "%u\n", $recv->len
  printf "Start lsn of the log segment: "
  printf "%lu\n", $recv->start_lsn
  printf "End lsn of the log segment: "
  printf "%lu\n", $recv->end_lsn

  # set $ptr=((char*)$recv->data) + sizeof(recv_data_t)
  set $ptr=((char*)$recv) + sizeof(recv_t)
  set $end_ptr=$ptr+$recv->len
  # MLOG_COMP_REC_INSERT
  if ($recv->type==38)
    printf "This is a MLOG_COMP_REC_INSERT (%u) record\n", ($recv->type)
    mysql_print_mlog_comp_rec_insert $ptr $end_ptr
  else
    # MLOG_COMP_REC_DELETE
    if ($recv->type==42)
      printf "This is a MLOG_COMP_REC_DELETE (%u) record\n", ($recv->type)
      mysql_print_mlog_comp_rec_delete $ptr $end_ptr
    else
      printf "This is a MLOG_XXX (%u) record\n", ($recv->type)
    end
  end
end

define mysql_print_recv_addr_t
  set $recv_addr=(recv_addr_t*)$arg0

  set logging overwrite on
  set logging file mysql_recv_addr_t.txt
  set logging on

  set pagination off

  printf "Space: "
  printf "%u\n", $recv_addr->space
  printf "Page no: "
  printf "%u\n", $recv_addr->page_no

  set $recv=(recv_t*)$recv_addr->rec_list.start
  set $cnt=0
  while (1)
    mysql_print_recv_t $recv

    set $recv=$recv->rec_list.next
    if ($recv==0x0)
      loop_break
    else
      set $cnt++
      printf "\n--- NEXT RECORD #%d---\n\n", $cnt
    end
  end
  set pagination on

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_sync_array
  set logging overwrite on
  set logging file mysql_sync_array.txt
  set logging on

  set pagination off
  set $i=0
  while $i<sync_array_size
    printf "sync_wait_array[%d]\n", $i
    set $arr=sync_wait_array[$i]
    printf "\tn_reserved: %u\n", $arr->n_reserved
    printf "\tn_cells: %u\n", $arr->n_cells
    printf "\tres_count: %u\n", $arr->res_count
    printf "\tnext_free_slot: %u\n", $arr->next_free_slot
    printf "\tfirst_free_slot: %u\n", $arr->first_free_slot
    set $j=$arr->first_free_slot+1
    while $j<$arr->next_free_slot
      set $cell=$arr->cells[$j]
      set $j++
      if (((WaitMutex*)$cell.latch)!=0x0) && ($cell.waiting)
        printf "\tsync_wait_array[%d]->cells[%d]\n", $i, ($j-1)
        printf "\t\trequest_type: %d", $cell.request_type
        # 0 - Unknow, 1 - Mutex, 2 - RWLock
        set $lock_type=0
        if ($cell.request_type==1)
          printf "-SYNC_MUTEX"
          set $lock_type=1
        end
        if ($cell.request_type==2)
          printf "-RW_LOCK_SX"
          set $lock_type=2
        end
        if ($cell.request_type==3)
          printf "-RW_LOCK_X_WAIT"
          set $lock_type=2
        end
        if ($cell.request_type==4)
          printf "-RW_LOCK_S"
          set $lock_type=2
        end
        if ($cell.request_type==5)
          printf "-RW_LOCK_X"
          set $lock_type=2
        end
        if ($cell.request_type==6)
          printf "-RW_LOCK_NOT_LOCKED"
          set $lock_type=2
        end
        printf "\n"
        printf "\t\tfile:line - %s:%d\n", $cell.file, $cell.line
        printf "\t\tthread_id: %lu\n", $cell.thread_id._M_thread
        if ($cell.waiting)
          printf "\t\twaiting: true\n"
        else
          printf "\t\twaiting: false\n"
        end
        printf "\t\tsignal_count: %ld\n", $cell.signal_count
        printf "\t\treservation_time: %lu\n", $cell.reservation_time
        if ($lock_type==1)
          # This is a WaitMutex
          printf "\t\tlatch.mutex: WaitMutex\n"
          set $mutex=(WaitMutex*)$cell.latch
          printf "\t\t\tpointer: %p\n", $mutex
          if ($mutex->m_lock_word._M_base._M_i)
            printf "\t\t\tm_lock_word: atomic operations enabled\n"
          else
            printf "\t\t\tm_lock_word: atomic operations disabled\n"
          end
          if ($mutex->m_waiters._M_base._M_i)
            printf "\t\t\tm_waiters: true\n"
          else
            printf "\t\t\tm_waiters: false\n"
          end
          printf "\t\t\tm_policy.m_id: %d\n", $mutex->m_policy.m_id
        end
        if ($lock_type==2)
          # This is a rw_lock_t
          printf "\t\tlatch.lock: rw_lock_t\n"
          set $rwlock=(rw_lock_t*)$cell.latch
          printf "\t\t\tpointer: %p\n", $rwlock
          printf "\t\t\tlock_word: %d\n", $rwlock->lock_word._M_i
          if $rwlock->waiters._M_base._M_i
            printf "\t\t\twaiters: TRUE\n"
          else
            printf "\t\t\twaiters: FALSE\n"
          end
          if $rwlock->recursive
            printf "\t\t\trecursive: TRUE\n"
          else
            printf "\t\t\trecursive: FALSE\n"
          end
          printf "\t\t\tsx_recursive: %u\n", $rwlock->sx_recursive
          if $rwlock->writer_is_wait_ex
            printf "\t\t\twriter_is_wait_ex: TRUE\n"
          else
            printf "\t\t\twriter_is_wait_ex: FALSE\n"
          end
          printf "\t\t\twriter_thread: %lu\n", $rwlock->writer_thread._M_i._M_thread
          printf "\t\t\tcfile_name:cline - %s:%d\n", $rwlock->cfile_name, $rwlock->cline
          printf "\t\t\tlast_s_file_name:last_s_line - %s:%d\n", $rwlock->last_s_file_name, $rwlock->last_s_line
          printf "\t\t\tlast_x_file_name:last_x_line - %s:%d\n", $rwlock->last_x_file_name, $rwlock->last_x_line
          printf "\t\t\tis_block_lock: %u\n", $rwlock->is_block_lock
          printf "\t\t\tcount_os_wait: %u\n", $rwlock->count_os_wait
        end
      end
    end
    set $i++
  end

  set pagination on

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_thd_real_id
  set $thd=((THD *) $arg0)

  printf "m_thread_id of THD %p: %u\n", $thd, $thd->m_thread_id
  printf "real_id of THD %p: %lu\n", $thd, $thd->real_id
  printf "m_query_string of THD %p: %s\n", $thd, $thd->m_query_string.str
end

define mysql_print_thd_array
  set $array=((THD **) (Global_THD_manager::thd_manager->thd_list.m_array_ptr))
  set $size=Global_THD_manager::atomic_global_thd_count._M_i-1

  set logging overwrite on
  set logging file mysql_thd_array.txt
  set logging on

  set pagination off
  printf "Length of the global THD array: %u\n", $size
  set $i=0
  while $i<$size
    set $thd=$array[$i]
    printf "THD[%d]: %p\n", $i, $thd
    if ($thd<0x1000)
      set $i++
      loop_continue
    end
    if ($thd->m_db.str!=0x0)
      printf "\tm_db: %s\n", $thd->m_db.str
    else
      printf "\tm_db: NULL\n"
    end
    if ($thd->m_query_string.str!=0x0)
      printf "\tm_query_string: %s\n", $thd->m_query_string.str
    else
      printf "\tm_query_string: NULL\n"
    end
    if ($thd->proc_info!=0x0)
      printf "\tproc_info: %s\n", $thd->proc_info
    else
      printf "\tproc_info: NULL\n"
    end
    if $thd->m_server_idle
      printf "\tm_server_idle: true\n"
    else
      printf "\tm_server_idle: false\n"
    end
    printf "\tquery_id: %ld\n", $thd->query_id
    printf "\treal_id: %lu\n", $thd->real_id
    printf "\tm_thread_id: %u\n", $thd->m_thread_id
    printf "\tstart_time: %ld\n", $thd->start_time.tv_sec
    if ($thd->system_thread>0)
      printf "\tUser: system user\n"
    end
    if ($thd->system_thread==0) && ($thd->m_security_ctx==0x0)
      printf "\tUser: N/A\n"
    end
    if ($thd->system_thread==0) && ($thd->m_security_ctx!=0x0)
      printf "\tUser: %s\n", $thd->m_security_ctx->m_user.m_ptr
      printf "\tHost: %s\n", $thd->m_security_ctx->m_host_or_ip.m_ptr
    end
    set $i++
  end
  set pagination on

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_innodb_os_ids
  set $read_only_mode=srv_read_only_mode
  set $enable_replica=srv_enable_replica
  set $enable_no_delay_read=srv_enable_no_delay_read
  if $enable_replica
    printf "This is a replica phoenix node\n"
  else
    printf "This is a primary phoenix node\n"
  end
  if $read_only_mode
    printf "This node is in read only mode"
  end
  printf "os thread id of buf_flush_page_cleaner_coordinator: %lu\n", page_cleaner_thread_ids[0]
  set $n=srv_n_page_cleaners
  set $i=1
  while ($i<$n)
    printf "os thread id of buf_flush_page_cleaner_worker[%d]: %lu\n", ($i-1), page_cleaner_thread_ids[$i]
    set $i++
  end
  printf "os thread id of buf_dump_thread: %lu\n", buf_dump_thread_id
  printf "os thread id of dict_stats_thread: %lu\n", dict_stats_thread_id
  printf "os thread id of buf_resize_thread: %lu\n", buf_resize_thread_id
  set $n=srv_n_file_io_threads
  set $i=0
  while ($i<$n)
    printf "os thread id of io_handler_thread[%d]: %lu\n", $i, thread_ids[$i]
    set $i++
  end
  if !$read_only_mode
    printf "os thread id of lock_wait_timeout_thread: %lu\n", thread_ids[132]
    printf "os thread id of srv_error_monitor_thread: %lu\n", thread_ids[133]
    printf "os thread id of srv_monitor_thread: %lu\n", thread_ids[134]
    printf "os thread id of srv_master_thread: %lu\n", thread_ids[131]
    if !$enable_replica
      printf "os thread id of srv_purge_coordinator_thread: %lu\n", thread_ids[135]
      set $n=srv_n_purge_threads
      set $i=1
      while ($i<$n)
        printf "os thread id of srv_worker_thread[%d]: %lu\n", ($i-1), thread_ids[135+$i]
        set $i++
      end
    end
  end
  if $enable_replica
    printf "os thread id of replica_invalidate_coordinator_thread: %lu\n", replica_invalidate_coordinator_thread_id
    printf "os thread id of replica_view_recycle_thread: %lu\n", replica_view_recycle_thread_id
    printf "os thread id of replica_invalidate_all_thread: %lu\n", replica_invalidate_all_thread_id
    printf "os thread id of replica_storage_node_synchronous_invalidator_thread: %lu\n", replica_storage_node_synchronous_invalidator_thread_id
    set $n=srv_n_replica_prefetch_io_threads
    set $i=0
    while ($i<$n)
      printf "os thread id of replica_invalidate_prefetch_thread[%d]: %lu\n", $i, replica_invalidate_prefetch_thread_ids[$i]
      set $i++
    end
  else
    printf "os thread id of primary_msg_send_thread: %lu\n", primary_msg_send_thread_id
    printf "os thread id of primary_msg_recv_thread: %lu\n", primary_msg_recv_thread_id
    if !$enable_no_delay_read
      printf "os thread id of primary_invalidate_thread: %lu\n", primary_invalidate_thread_id
    end
    printf "os thread id of primary_long_trx_check_thread: %lu\n", primary_long_trx_check_thread_id
  end
end

define mysql_print_mtr_memo_slot
  set $slot=(mtr_memo_slot_t*)$arg0
  if ($slot->object!=0x0)
    printf "memo slot: %p\n", $slot
    printf "memo object: %p\n", $slot->object
    if ($slot->type==1)
      set $block=(buf_block_t*)$slot->object
      printf "\tLock Type: MTR_MEMO_PAGE_S_FIX\n"
      printf "\tBlock ID: <%u, %u>\n", $block->page.id.m_space, $block->page.id.m_page_no
    end
    if ($slot->type==2)
      set $block=(buf_block_t*)$slot->object
      printf "\tLock Type: MTR_MEMO_PAGE_X_FIX\n"
      printf "\tBlock ID: <%u, %u>\n", $block->page.id.m_space, $block->page.id.m_page_no
    end
    if ($slot->type==4)
      set $block=(buf_block_t*)$slot->object
      printf "\tLock Type: MTR_MEMO_PAGE_SX_FIX\n"
      printf "\tBlock ID: <%u, %u>\n", $block->page.id.m_space, $block->page.id.m_page_no
    end
    if ($slot->type==8)
      set $block=(buf_block_t*)$slot->object
      printf "\tLock Type: MTR_MEMO_BUF_FIX\n"
      printf "\tBlock ID: <%u, %u>\n", $block->page.id.m_space, $block->page.id.m_page_no
    end
    if ($slot->type==64)
      printf "\tLock Type: MTR_MEMO_S_LOCK\n"
    end
    if ($slot->type==128)
      printf "\tLock Type: MTR_MEMO_X_LOCK\n"
    end
    if ($slot->type==256)
      printf "\tLock Type: MTR_MEMO_SX_LOCK\n"
    end
  end
end

define mysql_print_mtr_dynblock
  set $block=(mtr_buf_t::block_t*)$arg0
  set $start=(void*)$block->m_data
  set $end=(void*)$block->m_data+$block->m_used
  set $size=sizeof(mtr_memo_slot_t)
  while($end!=$start)
    set $end=$end-$size
    mysql_print_mtr_memo_slot $end
  end
end

define mysql_print_mtr_lock
  set logging overwrite on
  set logging file mysql_mtr_lock.txt
  set logging on

  set pagination off
  set $mtr=(mtr_t*)$arg0
  set $item=$mtr->m_impl.m_memo->m_list.end
  while($item!=0x0)
    printf "dynblock: %p\n", $item
    mysql_print_mtr_dynblock $item
    set $item=$item->m_node.prev
  end
  set pagination on

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_rw_lock_debug_info
  set $lock=(rw_lock_t*)$arg0
  set $info=$lock->debug_list.start
  while($info!=0x0)
    printf "rw_lock_debug_t: %p\n", $info
    printf "\tthread_id: %lu\n", $info.thread_id
    printf "\tpass: %u\n", $info.pass
    if ($info.lock_type==3)
      printf "\tlock_type: RW_LOCK_X_WAIT\n"
    end
    if ($info.lock_type==4)
      printf "\tlock_type: RW_LOCK_S\n"
    end
    if ($info.lock_type==5)
      printf "\tlock_type: RW_LOCK_X\n"
    end
    printf "\tfile_name:line - %s:%d\n", $info.file_name, $info.line
    set $info=$info.list.next
  end
end

define mysql_print_trx_list
  set $trx=(trx_t*)trx_sys->trx_list.start
  while($trx!=0x0)
    printf "trx_t: %p\n", $trx
    printf "\tid: %lu\n", $trx->id
    printf "\tno: %lu\n", $trx->no
    printf "\tcommit_lsn: %lu\n", $trx->commit_lsn
    printf "\tmysql_thd: %p\n", $trx->mysql_thd
    if ($trx->state==0)
      printf "\tstate: TRX_STATE_NOT_STARTED\n"
    end
    if ($trx->state==1)
      printf "\tstate: TRX_STATE_FORCED_ROLLBACK\n"
    end
    if ($trx->state==2)
      printf "\tstate: TRX_STATE_ACTIVE\n"
    end
    if ($trx->state==3)
      printf "\tstate: TRX_STATE_PREPARED\n"
    end
    if ($trx->state==4)
      printf "\tstate: TRX_STATE_COMMITTED_IN_MEMORY\n"
    end
    if ($trx->purge_sys_trx)
      printf "\tpurge_sys_trx: true\n"
    else
      printf "\tpurge_sys_trx: false\n"
    end
    if ($trx->is_background)
      printf "\tis_background: true\n"
    else
      printf "\tis_background: false\n"
    end
    set $trx=(trx_t*)$trx.trx_list.next
  end
end

define log_block_get_hdr_no
  set $c0=*(unsigned char*)((char*)$arg0)
  set $c1=*(unsigned char*)((char*)$arg0+1)
  set $c2=*(unsigned char*)((char*)$arg0+2)
  set $c3=*(unsigned char*)((char*)$arg0+3)
  printf "%u\n", ~0x80000000UL & ((unsigned int)$c0 << 24) + ((unsigned int)$c1 << 16) + ((unsigned int)$c2 << 8) + ((unsigned int)$c3)
end

define mysql_print_log_block
  set $block=(char*)$arg0

  set $block_number=$block
  printf "LOG_BLOCK_HDR_NO: "
  log_block_get_hdr_no $block_number

  set $data_length=$block_number+4
  printf "LOG_BLOCK_HDR_DATA_LEN: "
  mach_read_from_2 $data_length

  set $first_rec_offset=$data_length+2
  printf "LOG_BLOCK_FIRST_REC_GROUP: "
  mach_read_from_2 $first_rec_offset

  set $checkpoint_no=$first_rec_offset+2
  printf "LOG_BLOCK_CHECKPOINT_NO: "
  mach_read_from_4 $checkpoint_no

  set $block_checksum=$block+512-4
  printf "LOG_BLOCK_CHECKSUM: "
  hex_read_from_4 $block_checksum
end

define mysql_print_log_record
  set $record=(char*)$arg0

  set $mlog_type=$record
  printf "MLOG_TYPE: "
  mach_read_from_1 $mlog_type

  set $mlog_space_id=$mlog_type+1
  printf "MLOG_SPACE_ID: "
  mach_read_from_4 $mlog_space_id

  set $mlog_page_no=$mlog_space_id+4
  printf "MLOG_PAGE_NO: "
  mach_read_from_4 $mlog_page_no
end

define mysql_print_buf_flush_list
  set logging overwrite on
  set logging file mysql_buf_flush_list.txt
  set logging on

  set pagination off
  set $buf_pool=(buf_pool_t*)$arg0
  set $item=$buf_pool->flush_list.end
  while($item!=0x0)
    printf "bpage %p\n", $item
    print *((buf_page_t*)$item)
    set $item=$item->list.prev
  end
  set pagination on

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_buf_pool_all
  set logging overwrite on
  set logging file mysql_buf_pool_all.txt
  set logging on

  set pagination off
  set $n_instances=srv_buf_pool_instances
  set $i=0
  while ($i<$n_instances)
    printf "buf_pool_ptr[%d]: (buf_pool_t *) %p\n", $i, &(buf_pool_ptr[$i])
    set $j=0
    set $n_chunks=buf_pool_ptr[$i].n_chunks
    while ($j<$n_chunks)
      printf "\tbuf_pool_ptr[%d].chunks[%d]: (buf_chunk_t *) %p\n", $i, $j, &(buf_pool_ptr[$i].chunks[$j])
      set $k=0
      set $n_blocks=buf_pool_ptr[$i].chunks[$j].size
      while ($k<$n_blocks)
        printf "\t\tbuf_pool_ptr[%d].chunks[%d].blocks[%d]: (buf_block_t *) %p\n", $i, $j, $k, &(buf_pool_ptr[$i].chunks[$j].blocks[$k])
        printf "\t\tpage_id=%u:%u frame=%p\n", buf_pool_ptr[$i].chunks[$j].blocks[$k].page.id.m_space, buf_pool_ptr[$i].chunks[$j].blocks[$k].page.id.m_page_no, buf_pool_ptr[$i].chunks[$j].blocks[$k].frame
        set $k++
      end
      set $j++
    end
    set $i++
  end
  set pagination on

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_undo_list
  set $undo=(trx_undo_t*)$arg0
  while($undo!=0x0)
    printf "\t\ttrx_undo_t: %p\n", $undo
    printf "\t\t\tid: %lu\n", $undo->id
    if ($undo->type == 1)
      printf "\t\t\ttype: TRX_UNDO_INSERT\n"
    else
      printf "\t\t\ttype: TRX_UNDO_UPDATE\n"
    end
    if ($undo->state == 1)
      printf "\t\t\tstate: TRX_UNDO_ACTIVE\n"
    end
    if ($undo->state == 2)
      printf "\t\t\tstate: TRX_UNDO_CACHED\n"
    end
    if ($undo->state == 3)
      printf "\t\t\tstate: TRX_UNDO_TO_FREE\n"
    end
    if ($undo->state == 4)
      printf "\t\t\tstate: TRX_UNDO_TO_PURGE\n"
    end
    if ($undo->state == 5)
      printf "\t\t\tstate: TRX_UNDO_PREPARED\n"
    end
    printf "\t\t\tdel_marks: %u\n", $undo->del_marks
    printf "\t\t\ttrx_id: %lu\n", $undo->trx_id
    printf "\t\t\tflag: %lu\n", $undo->flag
    if ($undo->gtid_allocated)
      printf "\t\t\tgtid_allocated: true\n"
    else
      printf "\t\t\tgtid_allocated: false\n"
    end
    printf "\t\t\tdict_operation: %u\n", $undo->dict_operation
    printf "\t\t\tspace: %u\n", $undo->space
    printf "\t\t\thdr_page_no: %u\n", $undo->hdr_page_no
    printf "\t\t\thdr_offset: %lu\n", $undo->hdr_offset
    printf "\t\t\tlast_page_no: %u\n", $undo->last_page_no
    printf "\t\t\tsize: %lu\n", $undo->size
    printf "\t\t\tempty: %lu\n", $undo->empty
    printf "\t\t\ttop_page_no: %u\n", $undo->top_page_no
    printf "\t\t\ttop_offset: %lu\n", $undo->top_offset
    printf "\t\t\ttop_undo_no: %lu\n", $undo->top_undo_no
    if ($undo->guess_block!=0x0)
      printf "\t\t\tguess_block: %p, frame: %p\n", $undo->guess_block, $undo->guess_block->frame
    else
      printf "\t\t\tguess_block: nullptr\n"
    end
    set $undo=(trx_undo_t*)$undo.undo_list.next
  end
end

define mysql_print_rsegs
  set $rsegs=((Rsegs)$arg0).m_rsegs
  set $num_rseg=((unsigned long int)$rsegs._M_impl._M_finish-(unsigned long int)$rsegs._M_impl._M_start)/sizeof(trx_rseg_t*)
  set $n=0
  while ($n<$num_rseg)
    set $rseg=(trx_rseg_t *)$rsegs._M_impl._M_start[$n]
    printf "\t------\n"
    printf "\trsegs[%u]: %p\n", $n, $rseg
    printf "\trsegs[%u].id: %u\n", $n, $rseg->id
    printf "\trsegs[%u].space_id: %u\n", $n, $rseg->space_id
    printf "\trsegs[%u].page_no: %u\n", $n, $rseg->page_no
    printf "\trsegs[%u].max_size: %u\n", $n, $rseg->max_size
    printf "\trsegs[%u].curr_size: %u\n", $n, $rseg->curr_size
    printf "\trsegs[%u].last_page_no: %u\n", $n, $rseg->last_page_no
    printf "\trsegs[%u].last_offset: %u\n", $n, $rseg->last_offset
    printf "\trsegs[%u].last_trx_no: %u\n", $n, $rseg->last_trx_no
    printf "\trsegs[%u].last_del_marks: %u\n", $n, $rseg->last_del_marks
    if ($rseg->update_undo_list.start!=0x0)
      printf "\trsegs[%u].update_undo_list:\n", $n
      mysql_print_undo_list $rseg->update_undo_list.start
    else
      printf "\trsegs[%u].update_undo_list: empty\n", $n
    end
    if ($rseg->update_undo_cached.start!=0x0)
      printf "\trsegs[%u].update_undo_cached:\n", $n
      mysql_print_undo_list $rseg->update_undo_cached.start
    else
      printf "\trsegs[%u].update_undo_cached: empty\n", $n
    end
    if ($rseg->insert_undo_list.start!=0x0)
      printf "\trsegs[%u].insert_undo_list:\n", $n
      mysql_print_undo_list $rseg->insert_undo_list.start
    else
      printf "\trsegs[%u].insert_undo_list: empty\n", $n
    end
    if ($rseg->insert_undo_cached.start!=0x0)
      printf "\trsegs[%u].insert_undo_cached:\n", $n
      mysql_print_undo_list $rseg->insert_undo_cached.start
    else
      printf "\trsegs[%u].insert_undo_cached: empty\n", $n
    end
    set $n++
  end
end

define mysql_print_rsegs_all
  set logging overwrite on
  set logging file mysql_rsegs_all.txt
  set logging on

  set pagination off
  printf "In TRX_SYS_SPACE:\n"
  mysql_print_rsegs trx_sys->rsegs
  set $spaces=(undo::spaces)->m_spaces
  set $num_space=((unsigned long int)$spaces._M_impl._M_finish-(unsigned long int)$spaces._M_impl._M_start)/8
  set $i=0
  while ($i<$num_space)
    set $space=$spaces._M_impl._M_start[$i]
    printf "In %p, %s, %u:\n", $space, $space->m_space_name, $space->m_id
    set $i++
    mysql_print_rsegs *($space->m_rsegs)
  end
  set pagination on

  set logging off
  set logging file gdb.txt
  set logging overwrite off
end

define mysql_print_flst_base_node
  set $base=(char*)$arg0

  set $flst_len=$base
  printf "FLST_LEN: "
  mach_read_from_4 $flst_len

  set $flst_first=$flst_len+4
  printf "FLST_FIRST (page): "
  mach_read_from_4 $flst_first
  printf "FLST_FIRST (boffset): "
  mach_read_from_2 ($flst_first+4)

  set $flst_last=$flst_first+6
  printf "FLST_LAST (page): "
  mach_read_from_4 $flst_last
  printf "FLST_LAST (boffset): "
  mach_read_from_2 ($flst_last+4)
end

define mysql_print_flst_node
  set $node=(char*)$arg0

  set $flst_prev=$node
  printf "FLST_PREV (page): "
  mach_read_from_4 $flst_prev
  printf "FLST_PREV (boffset): "
  mach_read_from_2 ($flst_prev+4)

  set $flst_next=$flst_prev+6
  printf "FLST_NEXT (page): "
  mach_read_from_4 $flst_next
  printf "FLST_NEXT (boffset): "
  mach_read_from_2 ($flst_next+4)
end
