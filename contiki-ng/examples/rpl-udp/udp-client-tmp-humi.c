#include "contiki.h"
#include "net/routing/routing.h"
#include "random.h"
#include "net/netstack.h"
#include "net/ipv6/uipbuf.h"
#include "dev/radio.h"
#include "net/ipv6/simple-udp.h"
#include "net/linkaddr.h"
#include "lib/sensors.h"
#include "batmon-sensor.h"
#include "board-peripherals.h"

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>

#include "sys/log.h"
#define LOG_MODULE "App"
#define LOG_LEVEL LOG_LEVEL_INFO

#define UDP_CLIENT_PORT 8765
#define UDP_SERVER_PORT 5678
#define SEND_INTERVAL (10 * CLOCK_SECOND)

static struct simple_udp_connection udp_conn;
static uint32_t rx_count;

PROCESS(udp_client_process, "UDP client temperature humidity");
AUTOSTART_PROCESSES(&udp_client_process);

static void
udp_rx_callback(struct simple_udp_connection *c,
                const uip_ipaddr_t *sender_addr,
                uint16_t sender_port,
                const uip_ipaddr_t *receiver_addr,
                uint16_t receiver_port,
                const uint8_t *data,
                uint16_t datalen)
{
  /* Packet metadata propagated from the last received radio frame. */
  int16_t rssi = (int16_t)uipbuf_get_attr(UIPBUF_ATTR_RSSI);
  uint16_t lqi = uipbuf_get_attr(UIPBUF_ATTR_LINK_QUALITY);
  LOG_INFO("Received response '%.*s' from ", (int)datalen, (const char *)data);
  LOG_INFO_6ADDR(sender_addr);
  LOG_INFO_(" | Packet RSSI: %d dBm | LQI: %u", (int)rssi, (unsigned)lqi);
  LOG_INFO_("\n");
  rx_count++;
}

PROCESS_THREAD(udp_client_process, ev, data)
{
  static struct etimer periodic_timer;
  static char str[96];
  static uip_ipaddr_t dest_ipaddr;
  static uint32_t tx_count;
  static uint32_t missed_tx_count;
  static int temperature;
  static int humidity;

  PROCESS_BEGIN();

  {
    radio_value_t tx_power;
    if(NETSTACK_RADIO.get_value(RADIO_PARAM_TXPOWER, &tx_power)
       == RADIO_RESULT_OK) {
      LOG_INFO("Configured TX power: %ld dBm\n", (long)tx_power);
    } else {
      LOG_INFO("Configured TX power: unavailable\n");
    }
  }


  SENSORS_ACTIVATE(batmon_sensor);
  SENSORS_ACTIVATE(hdc_1000_sensor);

  simple_udp_register(&udp_conn, UDP_CLIENT_PORT, NULL,
                      UDP_SERVER_PORT, udp_rx_callback);

  etimer_set(&periodic_timer, random_rand() % SEND_INTERVAL);
  while(1) {
    PROCESS_WAIT_EVENT_UNTIL(etimer_expired(&periodic_timer));

    if(NETSTACK_ROUTING.node_is_reachable() &&
       NETSTACK_ROUTING.get_root_ipaddr(&dest_ipaddr)) {

      if(tx_count % 10 == 0) {
        LOG_INFO("Tx/Rx/MissedTx: %" PRIu32 "/%" PRIu32 "/%" PRIu32 "\n",
                 tx_count, rx_count, missed_tx_count);
      }

      temperature = batmon_sensor.value(BATMON_SENSOR_TYPE_TEMP);
      humidity = hdc_1000_sensor.value(HDC_1000_SENSOR_TYPE_HUMID);

      if(temperature == BATMON_SENSOR_READING_ERROR || humidity < 0) {
        LOG_INFO("Sensor reading failed (temp=%d, humidity=%d)\n",
                 temperature, humidity);
      } else {
        /* HDC humidity value is assumed to be in hundredths of percent. */
        snprintf(str, sizeof(str),
                 "ID=%u, Temp=%d C, Humidity=%d.%02d%%",
                 (unsigned)linkaddr_node_addr.u8[7], temperature,
                 humidity / 100, humidity % 100);

        LOG_INFO("Sending '%s' to ", str);
        LOG_INFO_6ADDR(&dest_ipaddr);
        LOG_INFO_("\n");
        simple_udp_sendto(&udp_conn, str, strlen(str), &dest_ipaddr);
        tx_count++;
      }
    } else {
      LOG_INFO("Not reachable yet\n");
      if(tx_count > 0) {
        missed_tx_count++;
      }
    }

    etimer_set(&periodic_timer, SEND_INTERVAL - CLOCK_SECOND +
              (random_rand() % (2 * CLOCK_SECOND)));
  }

  PROCESS_END();
}
