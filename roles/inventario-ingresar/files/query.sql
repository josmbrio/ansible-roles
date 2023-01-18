do $$
declare
    id_search uuid;
   id_new uuid;
   id_result uuid;
   flag_var boolean := true;
begin

   SELECT id from public.inventariofe_equipo
   INTO id_search
   WHERE hostname = %s and delete_ts is null;
   
   if not found then

      while flag_var loop
         -- Generar id para nuevo equipo
         SELECT gen_random_uuid() 
         into id_new;
         
         -- Consultar si id existe
         SELECT id from public.inventariofe_equipo
	     INTO id_result
         WHERE id = id_new;
         
         
         if not found then
         
            -- Ingresar equipo
            INSERT INTO public.inventariofe_equipo 
            (id, version, create_ts, created_by, update_ts, updated_by, delete_ts, deleted_by, datacenter_id, 
            vdc_id, fila, rack, unidad, bahia, estado, tipo, hypervisor, clasificacion_id, contenedor, hostname, 
            sistema_operativo, descripcion, memoria_ram, cpu, marca_id, modelo, numero_serie, numero_parte, ips, 
            ipadm) 
            VALUES 
            (id_new,'1',(SELECT DATE_TRUNC('second',  CURRENT_TIMESTAMP::timestamp)),'ansible',(SELECT DATE_TRUNC('second', CURRENT_TIMESTAMP::timestamp)),'',null,'',%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);
	   	 
            flag_var = false;
            return;
	   	 
         end if;  
      end loop;
   end if;
   return;   
end; $$;
