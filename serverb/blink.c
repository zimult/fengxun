/* Blink Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/
#include "blink.h"
#include "connect.h"
#include "sccb.h"
#include "ov5640.h"	

#include "nvs.h"
#include "uart_test.h"

void nvs_flash_read()
{
	uint8_t *read_buf,i;
	nvs_handle my_handle;
	esp_err_t err;
	size_t required_size = 0;

	err = nvs_open("storage", NVS_READWRITE, &my_handle);
	if (err != ESP_OK) return ;

	err = nvs_get_blob(my_handle, "run_pam", NULL, &required_size);
	printf("read flash err=%d,required_size=%d\r\n",err,required_size);
	if ((err == ESP_OK )&&(required_size>0)&&(required_size<64)){

		read_buf = malloc(required_size);
		err = nvs_get_blob(my_handle, "run_pam", read_buf, &required_size);
		if (err == ESP_OK){
			if(flash_pass==read_buf[0]){
				car_num=read_buf[1];
				imagecut_size_w=read_buf[2];imagecut_size_w=(imagecut_size_w<<8)+read_buf[3];
				imagecut_size_h=read_buf[4];imagecut_size_h=(imagecut_size_h<<8)+read_buf[5];
				memcpy(sever_ID,read_buf+6,2);
				memcpy(sever_IP,read_buf+8,4);
				REMOTE_PORT=(read_buf[12]<<8)+read_buf[13];
				for(i=0;i<car_num;i++){
					camera_parameter[i].x=read_buf[14+9*i];camera_parameter[i].x=(camera_parameter[i].x<<8)+read_buf[15+9*i];
					camera_parameter[i].y=read_buf[16+9*i];camera_parameter[i].y=(camera_parameter[i].y<<8)+read_buf[17+9*i];
					memcpy(camera_parameter[i].carport,&read_buf[18+9*i],5);
				}
			}
			else {
					strcpy(camera_parameter[0].carport,"F101");
					camera_parameter[0].x=16;		camera_parameter[0].y=492;
					strcpy(camera_parameter[1].carport,"F102");
					camera_parameter[1].x=816;		camera_parameter[1].y=492;
					strcpy(camera_parameter[2].carport,"F103");
					camera_parameter[2].x=1616;		camera_parameter[2].y=492;
				}
		}
		free(read_buf);
//		if(debug==1){
//			err = nvs_get_blob(my_handle, "run_IP", NULL, &required_size);
//			if ((err == ESP_OK )&&(required_size>0)&&(required_size<32)){
//
//				read_buf = malloc(required_size);
//				err = nvs_get_blob(my_handle, "run_IP", read_buf, &required_size);
//				if (err == ESP_OK){
//					sever_IP4=read_buf[22];
//					printf("read flash sever_IP4=%d!\r\n",sever_IP4);
//				}
//				free(read_buf);
//			}
//		}
	}
	else {
		printf("read flash error!\r\n");
		debug=0;
		strcpy(camera_parameter[0].carport,"F101");
		camera_parameter[0].x=16;		camera_parameter[0].y=492;
		strcpy(camera_parameter[1].carport,"F102");
		camera_parameter[1].x=816;		camera_parameter[1].y=492;
		strcpy(camera_parameter[2].carport,"F103");
		camera_parameter[2].x=1616;		camera_parameter[2].y=492;
	}
	nvs_close(my_handle);
}

void app_main()
{
	nvs_flash_init();
//    nvs_flash_read();

	printf("Verson:%s\r\n",Verson);
    gpio_pad_select_gpio(BLUE);
    gpio_set_direction(BLUE, GPIO_MODE_OUTPUT);

    gpio_pad_select_gpio(RED);
    gpio_set_direction(RED, GPIO_MODE_OUTPUT);

    BLUE_ON;
    RED_ON;

    esp_efuse_read_mac(mac);

	printf("****************heapsize1: %d\r\n",xPortGetFreeHeapSize());
	photograph_init();
	RED_OFF;

    printf("****************heapsize2: %d\r\n",xPortGetFreeHeapSize());
    initialise_wifi();

    printf("****************heapsize3: %d\r\n",xPortGetFreeHeapSize());

    xTaskCreate(&TCP_Client, "TCP_Client_task1", 4096, NULL, 5, NULL);
    xTaskCreate(&photograph_loop, "photograph", 2048, NULL, 5, NULL);
    app_uart();

}
