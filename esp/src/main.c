/**
 * Copyright (c) 2018 Sean Stasiak. All rights reserved.
 * Developed by: Sean Stasiak <sstasiak@protonmail.com>
 * Refer to license terms in LICENSE; In the absence of such a file,
 * contact me at the above email address and I can provide you with one.
 */

#include "esp_common.h"
#include "espconn.h"
#include "gpio.h"
#include "freertos/FreeRTOS.h"
#include "uart.h"

#define SSID     "SSID"
#define PASS     "PASS"
#define LOCALIP  { 192,168,200,100 }
#define REMOTEIP { 192,168,200,139 }
#define PORT     6100

/******************************************************************************
 * FunctionName : user_rf_cal_sector_set
 * Description  : SDK just reversed 4 sectors, used for rf init data and paramters.
 *                We add this function to force users to set rf cal sector, since
 *                we don't know which sector is free in user's application.
 *                sector map for last several sectors : ABCCC
 *                A : rf cal
 *                B : rf init data
 *                C : sdk parameters
 * Parameters   : none
 * Returns      : rf cal sector
*******************************************************************************/
ICACHE_FLASH_ATTR
    uint32 user_rf_cal_sector_set(void)
{
    flash_size_map size_map = system_get_flash_size_map();
    uint32 rf_cal_sec = 0;

    switch (size_map) {
        case FLASH_SIZE_4M_MAP_256_256:
            rf_cal_sec = 128 - 5;
            break;

        case FLASH_SIZE_8M_MAP_512_512:
            rf_cal_sec = 256 - 5;
            break;

        case FLASH_SIZE_16M_MAP_512_512:
        case FLASH_SIZE_16M_MAP_1024_1024:
            rf_cal_sec = 512 - 5;
            break;

        case FLASH_SIZE_32M_MAP_512_512:
        case FLASH_SIZE_32M_MAP_1024_1024:
            rf_cal_sec = 1024 - 5;
            break;
        case FLASH_SIZE_64M_MAP_1024_1024:
            rf_cal_sec = 2048 - 5;
            break;
        case FLASH_SIZE_128M_MAP_1024_1024:
            rf_cal_sec = 4096 - 5;
            break;
        default:
            rf_cal_sec = 0;
            break;
    }

    return rf_cal_sec;
}

ICACHE_FLASH_ATTR
    static void recv_cb( void *parg, char *pdata, unsigned short len )
{
  static uint32_t cnt = 0;
  static uint32_t tprev = 0, tcurr;
  struct espconn * const pconn = parg;
  remot_info *premote = 0;

  /* lookup return path - hardcode later to see what happens to our throughput */
  if( espconn_get_connection_info(pconn, &premote, 0) != ESPCONN_OK )
    printf( "espconn_get_connection_info(pconn, &premote, 0) != ESPCONN_OK\r\n" );

  /* send it back! */
  pconn->proto.udp->remote_ip[0] = premote->remote_ip[0];
  pconn->proto.udp->remote_ip[1] = premote->remote_ip[1];
  pconn->proto.udp->remote_ip[2] = premote->remote_ip[2];
  pconn->proto.udp->remote_ip[3] = premote->remote_ip[3];
  pconn->proto.udp->remote_port = premote->remote_port;
  if( espconn_send(pconn, pdata, len) != ESPCONN_OK )
    printf( "espconn_send(pconn, pdata, len) != ESPCONN_OK\r\n" );

  if( !(cnt % 100) )
  {
    tcurr = system_get_time();
    printf( "recv_cb(): [%u us] %u, "IPSTR":%d\r\n", tcurr-tprev, cnt, IP2STR(premote->remote_ip), premote->remote_port  );
    tprev = tcurr;
  }
  cnt++;
}

ICACHE_FLASH_ATTR
    static void task( void *pargs )
{
  (void)pargs;

  /* station is STATION_IDLE at this point, kick it off */
  if( wifi_station_connect() == false )
    printf( "wifi_station_connect() == false\r\n" );

  printf( "waiting for ip assignment.\r\n" );
  while( wifi_station_get_connect_status() != STATION_GOT_IP )
    vTaskDelay( (100*2)/portTICK_RATE_MS );

  static esp_udp udp = {
    .remote_port = PORT,
    .local_port  = PORT,    /**< technically, this is all that's */
    .local_ip    = LOCALIP, /*   needed for rx only              */
    .remote_ip   = REMOTEIP
  };

  static struct espconn conn = {
    .type  = ESPCONN_UDP,
    .state = ESPCONN_NONE,
    .proto = { .udp = &udp },
    .recv_callback = 0,
    .sent_callback = 0,
    .link_cnt = 0,
    .reserve  = 0
  };

  if( espconn_create(&conn) != ESPCONN_OK )
    printf( "espconn_create(&conn) != ESPCONN_OK\r\n" );

  if( espconn_regist_recvcb(&conn, recv_cb) != ESPCONN_OK )
    printf( "espconn_regist_recvcb(&conn, recv_cb) != ESPCONN_OK\r\n" );

  while( TRUE )
  {
    /* monitor */
    printf( "rssi: %d dBm\r\n", wifi_station_get_rssi() );
    vTaskDelay( (1000*2)/portTICK_RATE_MS );
  }
}

ICACHE_FLASH_ATTR
    static void we_cb( System_Event_t *pevt )
{
  /* wifi event callback */
  switch( pevt->event_id )
  {
    case EVENT_STAMODE_SCAN_DONE:
      printf( "EVENT_STAMODE_SCAN_DONE\r\n" );
      break;
    case EVENT_STAMODE_CONNECTED:
      printf( "EVENT_STAMODE_CONNECTED\r\n" );
      break;
    case EVENT_STAMODE_DISCONNECTED:
      printf( "EVENT_STAMODE_DISCONNECTED\r\n" );
      break;
    case EVENT_STAMODE_AUTHMODE_CHANGE:
      printf( "EVENT_STAMODE_AUTHMODE_CHANGE\r\n" );
      break;
    case EVENT_STAMODE_GOT_IP:
      printf( "EVENT_STAMODE_GOT_IP\r\n" );
//    PIN_FUNC_SELECT( PERIPHS_IO_MUX_GPIO2_U, FUNC_U1TXD_BK );
//    UART_SetBaudrate( UART1, 921600 );
//    UART_SetPrintPort( UART1 );
      printf( "wifi_get_phy_mode(): " );
      switch( wifi_get_phy_mode() )
      {
        case PHY_MODE_11B:
          printf( "PHY_MODE_11B\r\n" );
          break;
        case PHY_MODE_11G:
          printf( "PHY_MODE_11G\r\n" );
          break;
        case PHY_MODE_11N:
          printf( "PHY_MODE_11N\r\n" );
          break;
        default:
          printf( "UNKNOWN\r\n" );
          break;
      }
      break;
    case EVENT_STAMODE_DHCP_TIMEOUT:
      printf( "EVENT_STAMODE_DHCP_TIMEOUT\r\n" );
      break;
    case EVENT_SOFTAPMODE_STACONNECTED:
      printf( "EVENT_SOFTAPMODE_STACONNECTED\r\n" );
      break;
    case EVENT_SOFTAPMODE_STADISCONNECTED:
      printf( "EVENT_SOFTAPMODE_STADISCONNECTED\r\n" );
      break;
    case EVENT_SOFTAPMODE_PROBEREQRECVED:
      printf( "EVENT_SOFTAPMODE_PROBEREQRECVED\r\n" );
      break;
    default:
      printf( "unhandled pevt->event_id : %u\r\n", pevt->event_id );
  }
}

ICACHE_FLASH_ATTR
    void user_init()
{
  system_update_cpu_freq( SYS_CPU_160MHZ ); /**< caution: freertos timers are all doublespeed at this point! */
  UART_SetBaudrate( UART0, 2000000 );

  printf( "SDK version: %s\r\n", system_get_sdk_version() );
  xTaskCreate( task, "task", 512, 0, 1, 0 );

  /* no assert() or hardware dbg'r is PAINFUL! */
  if( wifi_set_event_handler_cb(we_cb) == false )
    printf( "wifi_set_event_handler_cb(we_cb) == false\r\n" );
  if( wifi_set_opmode_current(STATION_MODE) == false )
    printf( "wifi_set_opmode_current(STATION_MODE) == false\r\n" );
  if( wifi_set_phy_mode(PHY_MODE_11N) == false )
    printf( "wifi_set_phy_mode(PHY_MODE_11N) == false\r\n" );
  if( wifi_station_set_hostname("supadupathingy") == false )
    printf( "wifi_station_set_hostname(\"supadupathingy\") == false\r\n" );

  static struct station_config cfg = {
    .ssid      = SSID,
    .password  = PASS,
    .bssid_set = 0,
    .bssid = { 0,0,0,0,0,0 }
  };
  if( wifi_station_set_config_current(&cfg) == false )
    printf( "wifi_station_set_config_current(&cfg) == false\r\n" );
  espconn_init();
}