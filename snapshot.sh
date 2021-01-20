#!/bin/bash

# Script snapshot que obtiene una «foto» del estado de los directorios contenidos en el fichero de 
# configuración,y que contenga el nombre cada directorio seguido de los nombres de los ficheros que hay en el mismo, 
# sus permisos de acceso y una suma de control de su contenido.

declare directory="/Snapshot"
declare snapshot_file="$directory/snapshot"
declare config_file

# Control de errores
error() {
	echo "$1" 1>&2
	exit 1
}

# Comprobación del fichero de configuración en caso que se
# tome por defecto y no este situado en la ruta esperada
check_configFile() {
	if [[ ! -f $config_file ]]
	then
		error "Fichero de configuración por defecto no existe en el lugar de por defecto: /root/Monitorizacion_de_ficheros/config_file"
	fi
}


# Función de limpieza del directorio /Snapshot
clean() {
	find "$directory" -mindepth 1 -maxdepth 1 -delete
	return 0
}

# Comprobación de los parametros de entrada
if [[ $# -gt 1 ]]
then
	if [[ $1 = "-c" ]]
	then
		clean
	else
		error "Comando incorrecto"
	fi
	if [[ -f $2 ]]
	then
		config_file=$2
	else
		echo "Fichero de configuración no existe: tomado el de por defecto"
		config_file="/root/Monitorizacion_de_ficheros/config_file"
		check_configFile
	fi
elif [[ $# -eq 1 ]]
then
	if [[ $1 = "-c" ]]
	then
		clean
		config_file="/root/Monitorizacion_de_ficheros/config_file"
		check_configFile
	elif [[ -f $1 ]]
	then
		config_file=$1
	fi
else
	echo "Fichero de configuración: tomado el de por defecto"
	config_file="/root/Monitorizacion_de_ficheros/config_file"
	check_configFile
fi


# Creación del directorio que contendra la "foto"

if [[ ! -d $directory ]]
then
	mkdir $directory
fi

# Creación del fichero que contendra la "foto" en el directorio /Snapshot

if [[ -f $snapshot_file ]]
then
	mv $snapshot_file "$directory/snapshot.$(date +%d-%m-%Y-%H:%M:%S)" 
fi
touch $snapshot_file 

# Creación del contenido de la foto del archivo snapshot

declare line=""
while read check_directory
do
	if [[ -d $check_directory ]]
	then
		line="$check_directory;"
		files=$(find $check_directory -mindepth 1 -maxdepth 1 -printf "%f,%M,\n")
		for file_info in $files
		do
			file_name=$(echo $file_info | cut -d"," -f1)
			declare information
			if [[ -d "$check_directory/$file_name" ]]
			then
				checksum="SumaNoCalculable(Directorio)"
				information="$file_info$checksum"
			elif [[ -b "$check_directory/$file_name" || -c "$check_directory/$file_name" || -h "$check_directory/$file_name" ]]
			then
				checksum="SumaNoCalculable(FicheroEspecial)"
				information="$file_info$checksum"
			else
				information="$file_info$(sha512sum $check_directory/$file_name | cut -d" " -f1)"
			fi
			line="$line$information;"
		done
		echo $line >> $snapshot_file
	fi
done < $config_file
echo "Foto tomada correctamente"
