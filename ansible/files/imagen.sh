#!/bin/bash

# Accedemos al directorio donde tenemos todos los ficheros
cd /usr/local/apache2
echo "Estoy en el directorio apache2"

# Construimos la imagen de contenedor con usuario root
sudo podman build -t httpd .
echo "Acabo de contruir la imagen de contenedor"

# Etiquetamos la imagen de contenedor con el tag de "casopractico2"
sudo podman tag docker.io/library/httpd:latest containerregistryandresabad.azurecr.io/httpd:casopractico2
echo "Acabo de etiquetar la imagen de contenedor"

# Subimos la imagen al registry
sudo podman push containerregistryandresabad.azurecr.io/httpd:casopractico2
echo "Desplegada la imagen en el registry"

exit