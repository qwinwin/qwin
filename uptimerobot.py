#!/usr/bin/env python3
# coding = utf-8
import httpx
import tg_bot
import click


@click.command()
@click.option('-d',
              '--duration',
              default=60,
              help='Duration of the dead node (hours)')
def main(duration):
    base_url = "https://api.uptimerobot.com/v2"
    get_url = f"{base_url}/getMonitors"
    del_url = f"{base_url}/deleteMonitor"
    api_key = 'api_key'
    headers = {
        'content-type': "application/x-www-form-urlencoded",
        'cache-control': "no-cache"
    }
    # statuses 9 means 'down'
    get_data = {
        'api_key': api_key,
        'format': 'json',
        'logs': '1',
        'statuses': "9"
    }
    resp = httpx.post(get_url, headers=headers, data=get_data).json()
    for item in resp['monitors']:
        print(
            f"{item['friendly_name']:<10} {item['url']:<15} {item['logs'][0]['duration']/3600:.2f}"
        )
        try:
            # delete monitor if down duration longer than 60 hours
            if item['logs'][0]['duration'] > duration * 3600:
                del_data = {'api_key': api_key, 'id': item['id']}
                del_resp = httpx.post(del_url, headers=headers, data=del_data)
                msg = f"*del monitor\: {item['friendly_name']}*"
                tg_bot.send_msg(msg, parse_mode="MarkdownV2")
                print(del_resp)
                print(msg)
        except Exception as e:
            print(e)


if __name__ == "__main__":
    main()
