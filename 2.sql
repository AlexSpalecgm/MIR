select
  -- Перемещаем last_5_min в начало
  (SELECT Count(1)
     FROM ows.PHIS_CH_STAT phis_ch_stat
    WHERE phis_ch.id = phis_ch_stat.Ol_physical_channel__oid
      AND phis_ch_stat.date_from > SYSDATE - INTERVAL '5' MINUTE
      AND trpt_status = 'A'
      AND mng_status = 'A') as last_5_min,

  -- Остальные столбцы
  decode(srv.name,'TS1','TS1.01','TS2','TS2.02','TS1ACQ','TS1ACQ.03','TS2ACQ','TS2ACQ.04',srv.name) as Netserver,
  phis_ch.name_in_server as Channel_Name,
  phis_ch.mng_status,
  case
    when nvl(sy_add_data.get_label_ro('OL_PHYSICAL_CHANNEL','Monitored',phis_ch.id),'N') = 'A' then 'A'
    when phis_ch.name_in_server like 'H2H_ABHAZ%' and
         (select count(1)
            from ol_physical_channel
           where amnd_state = 'A'
             and name_in_server like 'H2H_ABHAZ%'
             and mng_status || trpt_status || appl_status = 'AAA') >= 1 then 'A'
    else nvl(phis_ch.trpt_status, 'A')
  end as trpt_status,

  case
    when nvl(sy_add_data.get_label_ro('OL_PHYSICAL_CHANNEL','Monitored',phis_ch.id),'N') in ('A','C') then 'A'
    when phis_ch.name_in_server like 'H2H_ABHAZ%' and
         (select count(1)
            from ows.ol_physical_channel
           where amnd_state = 'A'
             and name_in_server like 'H2H_ABHAZ%'
             and mng_status || trpt_status || appl_status = 'AAA') >= 1 then 'A'
    else nvl(phis_ch.appl_status, 'A')
  end as appl_status,

  -- Channel_id перемещен в конец списка столбцов
  phis_ch.id as Channel_id

from ows.ol_physical_channel phis_ch
inner join ol_server srv on srv.id = phis_ch.ol_server__oid

where 1=1
  and srv.amnd_state='A'
  and phis_ch.amnd_state='A'
  and nvl(sy_add_data.get_label_ro('OL_SERVER', 'Monitored', srv.id), 'Y')='Y'
  and nvl(sy_add_data.get_label_ro('OL_PHYSICAL_CHANNEL','Monitored',phis_ch.id),'Y') IN ('Y', 'A', 'C')

order by Netserver, Channel_Name;
