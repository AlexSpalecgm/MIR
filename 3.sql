select
/* 20250131 - https://sdportal/changesn/982436 Galiullin I.I */
       (SELECT Count (1) FROM ows.PHIS_CH_STAT phis_ch_stat
        WHERE 1=1
          AND phis_ch.id = phis_ch_stat.Ol_physical_channel__oid
          AND phis_ch_stat.date_from > SYSDATE - INTERVAL '5' MINUTE
          AND trpt_status = 'A'
          AND mng_status = 'A') last_5_min,
       decode(srv.name,'TS1','TS1.01','TS2','TS2.02','TS1ACQ','TS1ACQ.03','TS2ACQ','TS2ACQ.04',srv.name) Netserver,
       phis_ch.name_in_server Channel_Name,
       phis_ch.mng_status,
       case
         when nvl(sy_add_data.get_label_ro('OL_PHYSICAL_CHANNEL','Monitored',phis_ch.id),'N') = 'A' then 'A'
/* Проставляем признак TPRT_STATUS = A для всех каналов банка Абхазии,
   если есть хотя бы один канал с таким статусом */
         when phis_ch.name_in_server like 'H2H_ABHAZ%' and
              (select count(1)
                 from ol_physical_channel
                where amnd_state = 'A'
                  and name_in_server like 'H2H_ABHAZ%'
                  and mng_status || trpt_status || appl_status = 'AAA') >= 1 then 'A'
         else
          nvl(phis_ch.trpt_status, 'A')
       end as trpt_status,
       case
         when nvl(sy_add_data.get_label_ro('OL_PHYSICAL_CHANNEL','Monitored',phis_ch.id),'N') in ('A','C') then 'A'
/* Проставляем признак APPL_STATUS = A для всех каналов банка Абхазии,
   если есть хотя бы один канал с таким статусом */
         when phis_ch.name_in_server like 'H2H_ABHAZ%' and
              (select count(1)
                 from ows.ol_physical_channel
                where amnd_state = 'A'
                  and name_in_server like 'H2H_ABHAZ%'
                  and mng_status || trpt_status || appl_status = 'AAA') >= 1 then 'A'
         else
          nvl(phis_ch.appl_status, 'A')
       end as appl_status,
       phis_ch.id Channel_id

  from ows.ol_physical_channel phis_ch
    inner join ol_server srv on srv.id = phis_ch.ol_server__oid

 where 1 = 1
   and srv.amnd_state = 'A'
   and phis_ch.amnd_state = 'A'
   and nvl(sy_add_data.get_label_ro('OL_SERVER', 'Monitored', srv.id), 'Y') = 'Y'
/*
** N - исключить канал из мониторинга
** A - по каналам, имеющим в поле TRPT_STATUS статус "Disconnected" по умолчанию, в выгрузке будет проставляться значение "A"
** С - по каналам, имеющим в поле APPL_STATUS статус "Sign Off" по умолчанию, в выгрузке будет проставляться значение "A"
*/
   and nvl(sy_add_data.get_label_ro('OL_PHYSICAL_CHANNEL','Monitored',phis_ch.id),'Y') IN ('Y', 'A', 'C')
order by Netserver, Channel_Name
