from openpyxl import load_workbook
from sys import argv

columna_inicial = 'F'

def next_column(col):
    i = ord(col)
    i = i + 1
    nch = chr(i)
    return nch

def agregar_hostname(hostname):
    agregar_dato(hostname, '14')

def detectar_columna_libre(columna_inicial):
    if worksheet[columna_inicial+'14'].value is None:
        return columna_inicial
    else:
        current_column = columna_inicial
        while worksheet[current_column+'14'].value is not None:
            current_column = next_column(current_column)
        return current_column

def agregar_dato(data, fila):
    worksheet[COLUMNA_LIBRE+fila] = data

def agregar_check_de_tarea(check):
    for task in range(16, 50+1):
        worksheet['F'+str(task)] = check

hostname = argv[1]
ipaddress = argv[2]
if argv[3] is None:
    nombre = hostname
else:
    nombre = argv[3]
file = '/root/Checklist_Servidores_'+nombre+'.xlsx'


if hostname is None or ipaddress is None:
    print("Debe ingresar el hostname y la IP")
    exit(1)

try:
    # Cargar el archivo excel
    workbook = load_workbook(file)
except:
    print("El archivo no existe o no es formato Excel")
    exit(1)

# Posicionarse en la hoja activa
worksheet = workbook.active

COLUMNA_LIBRE = detectar_columna_libre(columna_inicial)

agregar_dato(hostname, '14')
agregar_dato(ipaddress, '15')
for task in range(16, 50 + 1):
    agregar_dato('✓', str(task))

# Guardar archivo
workbook.save(file)


