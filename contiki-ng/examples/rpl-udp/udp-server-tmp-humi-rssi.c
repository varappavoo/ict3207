#include "contiki.h"
#include "net/routing/routing.h"
#include "net/netstack.h"
#include "net/ipv6/uipbuf.h"
#include "dev/radio.h"
#include "net/ipv6/simple-udp.h"
#include "sys/log.h"
#define LOG_MODULE "App"
#define LOG_LEVEL LOG_LEVEL_INFO

#define WITH_SERVER_REPLY 1
#define UDP_CLIENT_PORT 8765
#define UDP_SERVER_PORT 5678

static struct simple_udp_connection udp_conn;
PROCESS(udp_server_process, "UDP server");
AUTOSTART_PROCESSES(&udp_server_process);

static void
udp_rx_callback(struct simple_udp_connection *c,
                const uip_ipaddr_t *sender_addr, uint16_t sender_port,
                const uip_ipaddr_t *receiver_addr, uint16_t receiver_port,
                const uint8_t *data, uint16_t datalen)
{
  /* Packet metadata propagated from the last received radio frame. */
  int16_t rssi = (int16_t)uipbuf_get_attr(UIPBUF_ATTR_RSSI);
  uint16_t lqi = uipbuf_get_attr(UIPBUF_ATTR_LINK_QUALITY);
  LOG_INFO("Received request '%.*s' from ", (int)datalen, (const char *)data);
  LOG_INFO_6ADDR(sender_addr);
  LOG_INFO_(" | Packet RSSI: %d dBm | LQI: %u", (int)rssi, (unsigned)lqi);
  LOG_INFO_("\n");
#if WITH_SERVER_REPLY
  LOG_INFO("Sending response.\n");
  simple_udp_sendto(&udp_conn, data, datalen, sender_addr);
#endif
}

PROCESS_THREAD(udp_server_process, ev, data)
{
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

  NETSTACK_ROUTING.root_start();
  simple_udp_register(&udp_conn, UDP_SERVER_PORT, NULL,
                      UDP_CLIENT_PORT, udp_rx_callback);
  PROCESS_END();
}
