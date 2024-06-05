# -----------------------------------------------
# Token Extraction Script
# Erik Morris, January 30, 2024
#
# Extract words and saves them with appropriate speaker/gender tags
# -----------------------------------------------

form: "Set directories and choose intensity"
	sentence: "sound_directory", "/Sounds"
	sentence: "textgrid_directory", "/TextGrids"
	comment: "Which tier contains your word labels?"
		natural: "word_tier", "1"
	sentence: "output_directory", "/Tokens"
endform

# Error handling Step 1
# Make sure the paths contain final slashes to avoid issues (call procedure)
@cleanPath: sound_directory$
soundDir$ = "'cleanPath.out$'"
@cleanPath: textgrid_directory$
gridDir$ = "'cleanPath.out$'"
@cleanPath: output_directory$
outputDir$ = "'cleanPath.out$'"

# Main Body -------

# Cycle through the word tier and find each word, extract that word, save the file

# Get audio file list from the first directory (sound)
Create Strings as file list: "list", "'soundDir$'*.wav"
nb_files = Get number of strings

for lMain from 1 to nb_files
	select Strings list
	name_file$ = Get string: lMain

# Get speaker data from file name (this may change depending on how the labelling works out)
	speaker$ = mid$ ("'name_file$'", 1, 3) ; Three chars starting position 1
	gen$ = mid$ ("'name_file$'", 2, 1) ; One char starting position 5

# Opens the sound file
	Read from file: "'soundDir$''name_file$'"
	name$ = selected$ ("Sound")
	orig_sound = selected ("Sound") ; ID of original sound file

# Open the corresponding textgrid
	Read from file: "'gridDir$''name$'.TextGrid"
	grid_name$ = selected$ ("TextGrid")

# Start looping through the intervals -----------------------
	nb_intervals = Get number of intervals: word_tier
	for lInter from 1 to nb_intervals
		selectObject: "TextGrid 'grid_name$'"
		word_label$ = Get label of interval: word_tier, lInter
		if word_label$ <> ""
			start = Get starting point: word_tier, lInter
			end = Get end point: word_tier, lInter
			file_name$ = "'speaker$'_'word_label$'"

			# Should I add a buffer?
			selectObject: orig_sound
			word_extract = Extract part: start, end, "Rectangular", 1, "no"

			# Save the file
			Save as 24-bit WAV file: "'outputDir$''file_name$'.wav"

		endif ; Check word label not blank

	endfor ; Interval loop on word tier
# Clean up created objects, but not the list of files
	select all
	minus Strings list
	Remove
endfor ; Main loop through audio files in input directory
select Strings list
Remove
# clearinfo
writeInfoLine: "Finished, check results file."

# # # # # # # # # #
# #  Procedures # #
# # # # # # # # # #

# Check if the path string has a slash on the end, if not, add it and return
procedure cleanPath: .in$
	if not right$(.in$, 1) = "/"
		.out$ = "'.in$'" + "/"
	else
		.out$ = "'.in$'"
	endif
endproc