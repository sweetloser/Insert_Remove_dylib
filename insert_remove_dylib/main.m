//
//  main.m
//  insert_remove_dylib
//
//  Created by app2 on 2017/9/15.
//  Copyright © 2017年 app2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <getopt.h>
#import "Insert_dylib.h"
#import "Remove_dylib.h"

#define DEBUG_TARGET_PATH @"./MMCommon"
#define DEBUG_DYLIB_PATH @"KKKK.dylib"

void test(void){
    [Insert_dylib Insert_dylib:DEBUG_DYLIB_PATH targetFile:DEBUG_TARGET_PATH];
}

void print_usage(){
    fprintf(stderr, "insert_remove_dylib \n"
            "Usage: insert_remove_dylib [options] <mach-o-file>\n"
            "\n"
            "   where options are:\n"
            "       -i          inject a dylib to mach-o file\n"
            "       -r          remove a dylib in mach-o file\n");
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSString *target_path = nil;
        NSString *insert_dylib_path = nil;
        NSString *remove_dylib_path = nil;
        
        struct option longopts[] = {
            {"insert-dylib",        required_argument,      NULL,   'i'},
            {"remove-dylib",        required_argument,      NULL,   'r'},
            {NULL,                  0,                      NULL,   0},
            
        };
        int ch;
        BOOL errorFlag = NO;
        while ((ch = getopt_long(argc, (char * const *)argv, "i:r:", longopts, NULL)) != -1) {
            switch (ch) {
                case 'i':
                {
                    //获取注入的路径
                    insert_dylib_path = [NSString stringWithUTF8String:optarg];
                }
                    break;
                case 'r':
                {
                    remove_dylib_path = [NSString stringWithUTF8String:optarg];
                }
                    break;
                case 0:
                default:
                    errorFlag = YES;
                    break;
            }
        }
        if (errorFlag) {
            fprintf(stderr, "ERROR!!!\n");
            
            print_usage();
            
            exit(1);
        }
        if (optind < argc) {
            //获取target文件路径
            target_path = [NSString stringWithUTF8String:argv[optind]];
            
            if (insert_dylib_path) {
                //注入
                fprintf(stderr, "insert:%s\n",[insert_dylib_path UTF8String]);
                
                [Insert_dylib Insert_dylib:insert_dylib_path targetFile:target_path];
            }
            if (remove_dylib_path) {
                //移除
                fprintf(stderr, "remove:%s\n",[remove_dylib_path UTF8String]);
                [Remove_dylib Remove_dylib:remove_dylib_path targetFile:target_path];
            }
            if (insert_dylib_path==nil && remove_dylib_path==nil) {
                fprintf(stderr, "ERROR!!!\n");
                print_usage();
                exit(1);
            }
            fprintf(stderr, "completed!!!\n");
        }
        
    }
    return 0;
}





