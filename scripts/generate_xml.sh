#! /bin/sh -
# Author: Kirk Worley
# Objective: Create several XML files for individual images from a single XML file
# 	generated by CVAT. This parses the tags in the XML file from CVAT and creates several
#	XML files to be used with the create_tfrecord Python script. Note the XML files will
#	be named exactly the same as the image they correspond to.
# Usage: ./generate_xml [-f PATH_TO_CVAT_ANNOTATIONS] [-d DIRECTORY]
#	PATH_TO_CVAT_ANNOTATIONS: Filepath to the CVAT annotation XML file.
#	DIRECTORY: The directory to place the new XML files.
PROGNAME=$0

# Argument: Invalid flag provided.
invalid_flag() {
	echo Invalid flag. Use -h to display the usage options.
	exit 1
}

# Argument: -h
usage() {
  cat << EOF >&2
Usage: $PROGNAME [-h] [-d <dir>] [-f <file>]

-h: Displays the usage message.
-d <dir>: Directory in which to place the new XML files. If the directory does not exist, it will be created. Default directory ./new_xml_files.
-f <file>: Filepath to the CVAT generated XML file. Default file name is 'ANNOTATION_TASK'.
EOF
  exit 1
}

# Parse arguments from flags using getopts.
dir='./new_xml_files' file='ANNOTATION_TASK'
while getopts f:d:h o; do
  case $o in
    (f) file=$OPTARG;;
    (d) dir=$OPTARG;;
	(h) usage;;
    (*) invalid_flag
  esac
done
shift "$((OPTIND - 1))"

# Does directory exist?
if [ -d $dir ]
then
	if [ $dir = "." ]
	then
		echo "Generating XML files in current directory."
	else
		echo "Generating XML files in "$dir"."
	fi
else
	echo $dir "does not exist. Creating it."
	mkdir -p $dir
fi

# Does CVAT XML file exist as described by filepath?
if [ ! -f $file ]
then
	echo "[ERROR]: File '"$file"' does not exist. Exiting."
	exit 1
fi

# AWK script to generate XML files from a single CVAT XML file.
awk -v outdir="$dir" '
	BEGIN {
		# Field separators.
		FS="[< >\"]"
		
		# This is how to print to dir
		# print "I am a file." > outdir"/1.xml"
	}
	
	# First, parse the metadata, which should only occur once, and should
	# always occur before any annotations.
	/<created>/ {
		meta_date_created = $9
	}
	/<username>/ {
		meta_annotator = $11
	}
	
	# Parse data from a single annotation, starting with data about the image.
	/<image/ {
		annotation_img_name = $9
		# Remove .JPG from image name.
		new_annotation_filename = substr(annotation_img_name, 1, length(annotation_img_name)-4)
		annotation_img_width = $12
		annotation_img_height = $15
		
		# Once an image tag is located, we are creating a new XML file. This tag
		# will preceed <box> tags, so we must first print the metadata to the new
		# XML file.
		full_path = outdir "/" new_annotation_filename ".xml"
		print "<annotation>" > full_path
		print "<annotator>" meta_annotator "</annotator>" > full_path
		print "<filename>" annotation_img_name "</filename>" > full_path
		print "<created>" meta_date_created "</created>" > full_path
		print "<size>" > full_path
		print "<width>" annotation_img_width "</width>" > full_path
		print "<height>" annotation_img_height "</height>" > full_path
		print "<depth>3</depth>" > full_path
		print "</size>" > full_path
	}
	
	# Parse data for bounding boxes. These should always be between an opening <image>
	# tag and a closing </image> tag.
	/<box/ {
		object_name = $8
		# Remove comma from end of name.
		object_name = substr(object_name, 1, length(object_name)-1)
		bndbox_xmin = $11
		bndbox_ymin = $14
		bndbox_xmax = $17
		bndbox_ymax = $20
		object_occluded = $23
		
		# Make object tag in file.
		print "<object>" > full_path
		print "<name>" object_name "</name>" > full_path
		print "<pose>unspecified</pose>" > full_path
		print "<truncated>0</truncated>" > full_path
		print "<occluded>" object_occluded "</occluded>" > full_path
		print "<bndbox>" > full_path
		print "<xmin>" bndbox_xmin "</xmin>" > full_path
		print "<ymin>" bndbox_ymin "</ymin>" > full_path
		print "<xmax>" bndbox_xmax "</xmax>" > full_path
		print "<ymax>" bndbox_ymax "</ymax>" > full_path
		print "</bndbox>" > full_path
		print "</object>" > full_path
	}
	
	# Upon encountering a </image> tag, that signifies the end of a single
	# annotated image. Create an XML file using the data saved thus far.
	/<\/image>/ {
		# Close annotation tag.
		print "</annotation>" > full_path
	}
	
' $file