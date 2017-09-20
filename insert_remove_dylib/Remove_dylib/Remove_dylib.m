//
//  Remove_dylib.m
//  insert_remove_dylib
//
//  Created by app2 on 2017/9/16.
//  Copyright © 2017年 app2. All rights reserved.
//

#import "Remove_dylib.h"
#import <mach-o/loader.h>
#import <mach-o/fat.h>

@implementation Remove_dylib

+(void)Remove_dylib:(NSString *)dylib_path targetFile:(NSString *)target_path{
    NSFileManager *file_manager = [NSFileManager defaultManager];
    if (![file_manager fileExistsAtPath:target_path isDirectory:NO]) {
        fprintf(stderr, "error:target file not exist!!\n");
        //直接返回
        return;
    }
    char target_binary[1024] = {0};
    char buffer[4096] = {0};
    
    strlcpy(target_binary, [target_path UTF8String], sizeof(target_binary));
    
    //读取target文件(r+:以读/写方式打开文件，该文件必须存在。)
    FILE *target_fp = fopen(target_binary, "r+");
    
    if (target_fp == NULL) {
        fprintf(stderr, "open file error!!!");
        return;
    }
    fread(&buffer, sizeof(buffer), 1, target_fp);
    
    struct fat_header *fh = (struct fat_header *)buffer;
    
    switch (fh->magic) {
        case FAT_CIGAM:
        case FAT_MAGIC:
        {
            struct fat_arch* arch = (struct fat_arch*)&fh[1];
            int i;
            for (i=0; i<CFSwapInt32(fh->nfat_arch); i++) {
                fprintf(stderr, "removing to arch %i\n",CFSwapInt32(arch->cpusubtype));
                if (CFSwapInt32(arch->cputype) == CPU_TYPE_ARM64) {
                    [self remove_64:target_fp startAddress:CFSwapInt32(arch->offset) injectPath:dylib_path];
                }else{
                    [self remove_32:target_fp startAddress:CFSwapInt32(arch->offset) injectPath:dylib_path];
                }
                arch++;
            }
        }
            break;
        case MH_CIGAM_64:
        case MH_MAGIC_64:
        {
            fprintf(stderr, "Thin 64bit binary!\n");
            [self remove_64:target_fp startAddress:0 injectPath:dylib_path];
        }
            break;
        case MH_CIGAM:
        case MH_MAGIC:
        {
            fprintf(stderr, "Thin 32bit binary!\n");
            [self remove_32:target_fp startAddress:0 injectPath:dylib_path];
        }
            break;
        default:
            break;
    }
    fclose(target_fp);
    
}

+(void)remove_64:(FILE *)fp startAddress:(unsigned long)top injectPath:(NSString *)dylib_path{
    fseek(fp, top, SEEK_SET);
    struct mach_header_64 mach;
    fread(&mach, sizeof(struct mach_header_64), 1, fp);
    long load_command_start_address =  ftell(fp);
    struct load_command exist_cmd;
    char orig_dylib_name[1024] = {0};
    struct dylib_command orig_dylib;
    
    unsigned char load_command_buffer[4096];
    for (int i=0; i<mach.ncmds; i++) {
        fread(&exist_cmd, sizeof(struct load_command), 1, fp);
        if (exist_cmd.cmd == LC_LOAD_DYLIB) {
            //读取load command 的path
            fseek(fp, -sizeof(struct load_command), SEEK_CUR);
            fread(&orig_dylib, sizeof(struct dylib_command), 1, fp);
            fseek(fp, (unsigned long)orig_dylib.dylib.name.offset - sizeof(struct dylib_command), SEEK_CUR);
            fread(orig_dylib_name, sizeof(orig_dylib_name), 1, fp);
            if (!strcmp(orig_dylib_name, [dylib_path UTF8String])) {
                char filler[8] = {0};
                fseek(fp, (-1024)+(-(unsigned long)orig_dylib.dylib.name.offset), SEEK_CUR);
                
                //判断要移除的是不是最后一个load command
                if (i==mach.ncmds-1) {
                    //如果要移除的段是最后一段，则直接置‘\0’
                    for (int i=0; i<orig_dylib.cmdsize/8; i++) {
                        fwrite(filler, 8, 1, fp);
                    }
                }else{
                    fseek(fp, orig_dylib.cmdsize, SEEK_CUR);
                    long next_dylib_address = ftell(fp);
                    
                    long other_dylib_size = mach.sizeofcmds-(next_dylib_address-load_command_start_address);
                    
                    fread(&load_command_buffer, other_dylib_size, 1, fp);
                    fseek(fp, next_dylib_address-orig_dylib.cmdsize, SEEK_SET);
                    fwrite(&load_command_buffer, other_dylib_size, 1, fp);
                    //将最后的一段置为‘\0’
                    for (int i=0; i<orig_dylib.cmdsize/8; i++) {
                        fwrite(filler, 8, 1, fp);
                    }
                }
                //修改mach_header_64
                fseek(fp, top, SEEK_SET);
                mach.ncmds = mach.ncmds - 0x1;
                mach.sizeofcmds = mach.sizeofcmds - orig_dylib.cmdsize;
                fwrite(&mach, sizeof(struct mach_header_64), 1, fp);
                return;
            }
            long offset = (-1024) + (-(unsigned long)orig_dylib.dylib.name.offset) + orig_dylib.cmdsize;
            fseek(fp, offset, SEEK_CUR);
            continue;
        }
        fseek(fp, exist_cmd.cmdsize-sizeof(struct load_command), SEEK_CUR);
    }
    fprintf(stderr, "not found !!!\n");
}

+(void)remove_32:(FILE *)fp startAddress:(unsigned long)top injectPath:(NSString *)dylib_path{
    fseek(fp, top, SEEK_SET);
    struct mach_header mach;
    fread(&mach, sizeof(struct mach_header), 1, fp);
    long load_command_start_address =  ftell(fp);
    struct load_command exist_cmd;
    char orig_dylib_name[1024] = {0};
    struct dylib_command orig_dylib;
    
    unsigned char load_command_buffer[4096];
    for (int i=0; i<mach.ncmds; i++) {
        fread(&exist_cmd, sizeof(struct load_command), 1, fp);
        if (exist_cmd.cmd == LC_LOAD_DYLIB) {
            //读取load command 的path
            fseek(fp, -sizeof(struct load_command), SEEK_CUR);
            fread(&orig_dylib, sizeof(struct dylib_command), 1, fp);
            fseek(fp, (unsigned long)orig_dylib.dylib.name.offset - sizeof(struct dylib_command), SEEK_CUR);
            fread(orig_dylib_name, sizeof(orig_dylib_name), 1, fp);
            if (!strcmp(orig_dylib_name, [dylib_path UTF8String])) {
                char filler[8] = {0};
                fseek(fp, (-1024)+(-(unsigned long)orig_dylib.dylib.name.offset), SEEK_CUR);
                
                //判断要移除的是不是最后一个load command
                if (i==mach.ncmds-1) {
                    //如果要移除的段是最后一段，则直接置‘\0’
                    for (int i=0; i<orig_dylib.cmdsize/8; i++) {
                        fwrite(filler, 8, 1, fp);
                    }
                }else{
                    fseek(fp, orig_dylib.cmdsize, SEEK_CUR);
                    long next_dylib_address = ftell(fp);
                    
                    long other_dylib_size = mach.sizeofcmds-(next_dylib_address-load_command_start_address);
                    
                    fread(&load_command_buffer, other_dylib_size, 1, fp);
                    fseek(fp, next_dylib_address-orig_dylib.cmdsize, SEEK_SET);
                    fwrite(&load_command_buffer, other_dylib_size, 1, fp);
                    //将最后的一段置为‘\0’
                    for (int i=0; i<orig_dylib.cmdsize/8; i++) {
                        fwrite(filler, 8, 1, fp);
                    }
                }
                //修改mach_header_64
                fseek(fp, top, SEEK_SET);
                mach.ncmds = mach.ncmds - 0x1;
                mach.sizeofcmds = mach.sizeofcmds - orig_dylib.cmdsize;
                fwrite(&mach, sizeof(struct mach_header), 1, fp);
                return;
            }
            long offset = (-1024) + (-(unsigned long)orig_dylib.dylib.name.offset) + orig_dylib.cmdsize;
            fseek(fp, offset, SEEK_CUR);
            continue;
        }
        fseek(fp, exist_cmd.cmdsize-sizeof(struct load_command), SEEK_CUR);
    }
    fprintf(stderr, "not found !!!\n");
}

@end
