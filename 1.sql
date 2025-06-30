select
/* 20250131 - https://sdportal/changesn/982436 Galiullin I.I */

  (SELECT Count (1) FROM ows.PHIS_CH_STAT phis_ch_stat
   WHERE 1=1
     AND phis_ch.id = phis_ch_stat.Ol_physical_channel__oid
     AND phis_ch_stat.date_from > SYSDATE - INTERVAL '5' MINUTE
     AND trpt_status='A'
     AND mng_status='A') last_5_min,

       phis_ch.id Channel_id,
       decode(srv.name,'TS1','TS1.01','TS2','TS2.02','TS1ACQ','TS1ACQ.03','TS2ACQ','TS2ACQ.04',srv.name) Netserver,
       phis_ch.name_in_server Channel_Name,
       phis_ch.mng_status,
       case
         when nvl(sy_add_data.get_label_ro('OL_PHYSICAL_CHANNEL','Monitored',phis_ch.id),'N')='A' then'A'
/* Проставляем признак TPRT_STATUS=А для всех каналов банка Абхазии, если есть хотя бы один канал с таким статусом */
         when phis_ch.name_in_server like'H2H_ABHAZ%' and 
              (select count(1)
                 from ol_physical_channel 
                where amnd_state='А' 
                  and name_in_server like'H2H_ABHAZ%' 
                  and mng_status||trpt_status||appl_statuS='AAA')>=1 then'A' 
        else 
          nvl(phis_Ch.trpt_Status,'А')
        end as trpt_Status ,
        case 
          when nvl(sy_add_data.get_label_ro('OL_PHYSICAL_CHANNEL ',' Monitored ',phis_Ch.Id),'N') in ('А ','С ') then'A' 
/* Проставляем признак APPL_STATUS=А для всех каналов банка Абхазии , если есть хотя бы один канал с таким статусом */
          when PhIs_Ch.Name_In_Server Like'H2h_AbHaZ%' And 
               (Select Count( 1 ) From Ol_Physical_Channel Where Amnd_State='А' And Name_In_Server Like'H2h_AbHaZ%' And Mng_Status||TrPt_Status||Appl_Status='AAA' )>= 1 Then'A' 
        Else 
          Nvl(PhIs_Ch.Appl_Status,'А')
        End as Appl_Status 

from ows.ol_physical_channel PhIs_Ch 
inner join Ol_Server Srv on Srv.Id=PhIs_Ch.Ol_Server__Oid 

where 1=1 
and Srv.Amnd_State='А' 
and PhIs_Ch.Amnd_State='А' 
and Nvl(Sy_Add_Data.Get_Label_Ro('Ol_Server ',' Monitored ',Svr.Id ),'Y')='Y' 

/* N- исключить канал из мониторинга */
/* A- по каналам , имеющим в поле TrPt_Status статус « Disconnected » по умолчанию , в выгрузке будет проставляться значение « А » */
/* C- по каналам , имеющим в поле Appl_Status статус « Sign Off » по умолчанию , в выгрузке будет проставляться значение « А » */

and Nvl(Sy_Add_Data.Get_Label_Ro('Ol_Physical_Channel ',' Monitored ',PhIs_Ch.Id ),'Y') In ('Y ',' А ',' С ') 

order by NetServer ,Channel_Name ;
