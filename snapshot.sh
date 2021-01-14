#!/bin/bash

# Script snapshot que obtiene una «foto» del estado de los directorios contenidos en el fichero de 
# configuración,y que contenga el nombre cada directorio seguido de los nombres de los ficheros que hay en el mismo, 
# sus permisos de acceso y una suma de control de su contenido.

declare config_file

# Comprobación del parametro de entrada
if [[ $# -gt 0 ]]
then
	if [[ -f $1 ]]
	then
		config_file=$1
	else
		echo "Fichero de configuración no existe: tomado el de por defecto" 1>&2
		config_file="/root/Monitorizacion_de_ficheros/config_file"
	fi
else
	config_file="/root/Monitorizacion_de_ficheros/config_file"
fi

# Creación del fichero que contendra la "foto" en un directorio que cuelga del /

declare directory="/Snapshot"
#PENDIENTE
if [[ ! -d $directory ]]
then
	mkdir $directory
fi

directory="$directory/snapshot"
rm $directory 2>/dev/null
touch $directory 

# Contenido de la foto del archivo snapshot

declare line=""
while read check_directory
do
	if [[ -d $check_directory ]]
	then
		line="$check_directory:"
		files=$(find $check_directory -mindepth 1 -maxdepth 1 -printf "%f,%M,\n")
		for file_info in $files
		do
			file_name=$(echo $file_info | cut -d"," -f1)
			declare checksum
			# echo "$check_directory/$file_name"  ¿enlaces simbolicos muy grandes?
			if [[ -d "$check_directory/$file_name" ]]
			then
				checksum="Suma no calculable (Directorio)"
				checksum="$file_info$checksum"
			elif [[ -b "$check_directory/$file_name" || -c "$check_directory/$file_name" ]]
			then
				checksum="Suma no calculable (Fichero especial)"
				checksum="$file_info$checksum"
			else
				checksum="$file_info$(sha512sum $check_directory/$file_name | cut -d" " -f1)"
			fi
			line="$line$checksum;"
		done
		echo $line >> $directory
	fi
done < $config_file
echo "Foto tomada correctamente"
