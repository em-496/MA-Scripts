# -----------------------------------------------
# Label the intervals
# Erik Morris, April 8, 2024
#
# Script assumes text file, sound and grid have the same name,
# Text file should contain each label on a separate line
# -----------------------------------------------

# Be sure to enter correct directory here first
soundDir$ = "/Users/"
targ_tier = 1

# Get audio file list from the first directory (sound)
Create Strings as file list: "list", "'soundDir$'*.wav"
nb_files = Get number of strings

# ------- Main Body --------

for lMain from 1 to nb_files
	select Strings list
	name_file$ = Get string: lMain
# Opens the sound file
	Read from file: "'soundDir$''name_file$'"
	name$ = selected$ ("Sound")
	orig_sound = selected ("Sound") ; ID of original sound file

# Open the corresponding textgrid
	Read from file: "'soundDir$''name$'.TextGrid"
	grid_name$ = selected$ ("TextGrid")
	nb_intervals = Get number of intervals: targ_tier

# Open the word list
	labels_list = Read Strings from raw text file: "'soundDir$''name$'.txt"
	word_count = 1

## Run through the intervals and find the ones marked by "x" which should be a word
## Take the label from the list of strings, read from a text file, and replace the label
	for lInter from 1 to nb_intervals
		selectObject: "TextGrid 'grid_name$'"
		targ_label$ = Get label of interval: targ_tier, lInter
		if targ_label$ = "x"
			selectObject: labels_list
			new_label$ = Get string: word_count
			selectObject: "TextGrid 'grid_name$'"
			Set interval text: targ_tier, lInter , new_label$
			word_count += 1
		endif
	endfor

# Save the Grid
	selectObject: "TextGrid 'grid_name$'"
	#Save whole TextGrid as text file: "'soundDir$''name$'_labeled.TextGrid"
	Write to text file: "'soundDir$''name$'_labeled.TextGrid"
endfor ; Main loop

select all
Remove
clearinfo
writeInfoLine: "Finished, check results file."