//
//  LiveUIParView.m
//  TILLiveSDKShow
//
//  Created by wilderliao on 16/11/9.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import "LiveUIParView.h"
#import <ILiveSDK/ILiveQualityData.h>

@interface LiveUIParView () <TIMAVMeasureSpeederDelegate>
{
    UInt64  _channelId;
}
@property (nonatomic, strong) TIMAVMeasureSpeeder *measureSpeeder;
@end

UIAlertController *_alert;

@implementation LiveUIParView


- (instancetype)init
{
    if (self = [super init])
    {
        [self addAVParamSubViews];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onParPure:) name:kPureDelete_Notification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onParNoPure:) name:kNoPureDelete_Notification object:nil];
    }
    return self;
}

- (void)onParPure:(NSNotification *)noti
{
    self.hidden = YES;
}
- (void)onParNoPure:(NSNotification *)noti
{
    self.hidden = NO;
}
- (void)addAVParamSubViews
{
    //AV Param View
    _interactBtn = [[UIButton alloc] init];
    [_interactBtn setImage:[UIImage imageNamed:@"interactive"] forState:UIControlStateNormal];
    [_interactBtn addTarget:self action:@selector(onInteract:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_interactBtn];
    
    UIImage *nor = [UIImage imageWithColor:[RGB(220, 220, 220) colorWithAlphaComponent:0.5]];
    UIImage *hig = [UIImage imageWithColor:[RGB(110, 110, 110) colorWithAlphaComponent:0.5]];
    
    _parBtn = [[UIButton alloc] init];
    [_parBtn setTitle:@"PAR" forState:UIControlStateNormal];
    _parBtn.titleLabel.font = kAppMiddleTextFont;
    [_parBtn addTarget:self action:@selector(onPar:) forControlEvents:UIControlEventTouchUpInside];
    [_parBtn setTitleColor:kColorBlack forState:UIControlStateNormal];
    [_parBtn setTitleColor:kColorWhite forState:UIControlStateSelected];
    
    [_parBtn setBackgroundImage:nor forState:UIControlStateNormal];
    [_parBtn setBackgroundImage:hig forState:UIControlStateSelected];
    
    _parBtn.layer.cornerRadius = 4;
    _parBtn.layer.masksToBounds = YES;
    [self addSubview:_parBtn];
    
    _pushStreamBtn = [[UIButton alloc] init];
    
    [_pushStreamBtn setTitle:@"开始推流" forState:UIControlStateNormal];
    [_pushStreamBtn setTitle:@"关闭推流" forState:UIControlStateSelected];
    [_pushStreamBtn addTarget:self action:@selector(onPush:) forControlEvents:UIControlEventTouchUpInside];
    if (self.bounds.size.width <= 320)
    {
        _pushStreamBtn.titleLabel.font = kAppSmallTextFont;
    }
    else
    {
        _pushStreamBtn.titleLabel.font = kAppMiddleTextFont;
    }
    [_pushStreamBtn setTitleColor:kColorBlack forState:UIControlStateNormal];
    [_pushStreamBtn setTitleColor:kColorWhite forState:UIControlStateSelected];
    
    [_pushStreamBtn setBackgroundImage:nor forState:UIControlStateNormal];
    [_pushStreamBtn setBackgroundImage:hig forState:UIControlStateSelected];
    
    _pushStreamBtn.layer.cornerRadius = 4;
    _pushStreamBtn.layer.masksToBounds = YES;
    [self addSubview:_pushStreamBtn];
    
    UIImage *recHig = [UIImage imageWithColor:[kColorBlue colorWithAlphaComponent:0.5]];
    _recBtn = [[UIButton alloc] init];
    
    [_recBtn setTitle:@"REC" forState:UIControlStateNormal];
    [_recBtn addTarget:self action:@selector(onRecord:) forControlEvents:UIControlEventTouchUpInside];
    _recBtn.titleLabel.font = kAppMiddleTextFont;
    [_recBtn setTitleColor:kColorBlack forState:UIControlStateNormal];
    [_recBtn setTitleColor:kColorWhite forState:UIControlStateSelected];
    
    [_recBtn setBackgroundImage:nor forState:UIControlStateNormal];
    [_recBtn setBackgroundImage:recHig forState:UIControlStateSelected];
    
    _recBtn.layer.cornerRadius = 4;
    _recBtn.layer.masksToBounds = YES;
    [self addSubview:_recBtn];
    
    
    _speedBtn = [[UIButton alloc] init];
    
    [_speedBtn setTitle:@"测速" forState:UIControlStateNormal];
    [_speedBtn addTarget:self action:@selector(onTestSpeed:) forControlEvents:UIControlEventTouchUpInside];
    _speedBtn.titleLabel.font = kAppMiddleTextFont;
    [_speedBtn setTitleColor:kColorBlack forState:UIControlStateNormal];
    
    [_speedBtn setBackgroundImage:nor forState:UIControlStateNormal];
    [_speedBtn setBackgroundImage:recHig forState:UIControlStateSelected];
    
    _speedBtn.layer.cornerRadius = 4;
    _speedBtn.layer.masksToBounds = YES;
    [self addSubview:_speedBtn];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    
    NSMutableArray *funs = [NSMutableArray array];
    if (_isHost)
    {
        [funs addObjectsFromArray:@[_interactBtn,_parBtn,_pushStreamBtn,_recBtn,_speedBtn]];
    }
    else
    {
        [funs addObjectsFromArray:@[_parBtn,_pushStreamBtn,_recBtn,_speedBtn]];
    }
    
    NSInteger width = (rect.size.width - (funs.count + 1)*3) / funs.count;
    
    if (width > 80)
    {
        width = 80;
    }
    [self gridViews:funs inColumn:funs.count size:CGSizeMake(width, 24) margin:CGSizeMake(3, 3) inRect:rect];
}

- (void)onInteract:(UIButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onInteract)])
    {
        [self.delegate onInteract];
    }
}

- (void)onPar:(UIButton *)button
{
    if (!button.selected)
    {
        _paramTextView = [[UITextView alloc] init];
        CGRect selfRect = self.frame;
        _paramTextView.editable = NO;
        [_paramTextView setFrame:CGRectMake(0, selfRect.origin.y+selfRect.size.height+kDefaultMargin, selfRect.size.width, 350)];
        _paramTextView.backgroundColor = [kColorLightGray colorWithAlphaComponent:0.5];
        [self.superview addSubview:_paramTextView];
        
        //判断相机状态
        QAVContext *context = [[ILiveSDK getInstance] getAVContext];
        
        if (context.videoCtrl && context.audioCtrl && context.room)
        {
//            NSString *videoParam = [context.videoCtrl getQualityTips];
//            NSString *audioParam = [context.audioCtrl getQualityTips];
//            NSString *commonParam = [context.room getQualityTips];
//            NSString *paramText = [NSString stringWithFormat:@"Video:\n%@Audio:\n%@Common:\n%@", videoParam, audioParam, commonParam];
            ILiveQualityData *qualityData = [[ILiveRoomManager getInstance] getQualityData];
            NSMutableString *paramString = [NSMutableString string];
            
            CGFloat sendLossRate = (CGFloat)qualityData.sendLossRate / (CGFloat)100;
            CGFloat recvLossRate = (CGFloat)qualityData.recvLossRate / (CGFloat)100;
            
            NSString *per = @"%";
            [paramString appendString:[NSString stringWithFormat:@"SendLossRate: %.2f%@   RecvLossRate: %.2f%@\n",sendLossRate,per,recvLossRate,per]];
            
            CGFloat appCpuRate = (CGFloat)qualityData.appCPURate / (CGFloat)100;
            CGFloat sysCpuRate = (CGFloat)qualityData.sysCPURate / (CGFloat)100;
            [paramString appendString:[NSString stringWithFormat:@"AppCPURate:   %.2f%@   SysCPURate:   %.2f%@\n",appCpuRate,per,sysCpuRate,per]];
            
            [paramString appendString:[NSString stringWithFormat:@"Send:   %ldkbps   Recv:   %ldkbps\n",(long)qualityData.sendRate,(long)qualityData.recvRate]];
            
            
            NSString *videoParam = [context.videoCtrl getQualityTips];
            NSArray *array = [videoParam componentsSeparatedByString:@"\n"]; //从字符A中分隔成2个元素的数组
            if (array.count > 3)
            {
                NSString *resolution = [array objectAtIndex:2];
                [paramString appendString:[NSString stringWithFormat:@"%@\n",resolution]];
            }
            _paramTextView.text = paramString;
        }
    }
    else
    {
        if (_paramTextView)
        {
            [_paramTextView removeFromSuperview];
        }
    }
    button.selected = !button.selected;
}

- (void)onPush:(UIButton *)button
{
    button.selected = !button.selected;
    
    if (button.selected)
    {
        __weak typeof(self) ws = self;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"HLS推流" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

            [ws pushStream:button type:AV_ENCODE_HLS];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"RTMP推流" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [ws pushStream:button type:AV_ENCODE_RTMP];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            button.selected = !button.selected;
        }]];
        
        [[AppDelegate sharedAppDelegate].navigationViewController presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [self stopPushStream];
    }
}

- (void)pushStream:(UIButton *)button type:(AVEncodeType)type
{
    ILivePushOption *option = [[ILivePushOption alloc] init];
    
    ILiveChannelInfo *info = [[ILiveChannelInfo alloc] init];
    info.channelName = [NSString stringWithFormat:@"新随心播推流_%@",[[ILiveLoginManager getInstance] getLoginId]];
    info.channelDesc = [NSString stringWithFormat:@"新随心播推流描述测试文本"];
    
    option.channelInfo = info;
    
    option.encodeType = type;
    option.sdkType = AVSDK_TYPE_NORMAL;
    
    __weak typeof(self) ws = self;
    [[ILiveRoomManager getInstance] startPushStream:option succ:^(id selfPtr) {
        
        AVStreamerResp *resp = (AVStreamerResp *)selfPtr;
        NSLog(@"--->resp %@",resp);
        
        [ws setChannelId:resp.channelID];
        
        AVLiveUrl *url = nil;
        if (resp && resp.urls && resp.urls.count > 0)
        {
            url = resp.urls[0];
        }
        NSString *msg = url ? url.playUrl : nil;
        [ws showAlert:@"推流成功" message:msg okTitle:@"复制到剪贴板" cancelTitle:@"取消" ok:^(UIAlertAction * _Nonnull action) {
            
            if (msg)
            {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                [pasteboard setString:msg];
            }
            
        } cancel:nil];
        
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        
        button.selected = !button.selected;
        NSString *errinfo = [NSString stringWithFormat:@"push stream fail.module=%@,errid=%d,errmsg=%@",module,errId,errMsg];
        NSLog(@"%@",errinfo);
        [ws showAlert:@"推流失败" message:errinfo okTitle:@"确认" cancelTitle:nil ok:nil cancel:nil];
    }];
    
}

- (void)stopPushStream
{
    __weak typeof(self) ws = self;
    
    [[ILiveRoomManager getInstance] stopPushStreams:@[@(_channelId)] succ:^{
        
        [ws setChannelId:0];//重置channelid
        [ws showAlert:@"已停止推流" message:nil okTitle:@"确认" cancelTitle:nil ok:nil cancel:nil];
        
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        
        NSString *errinfo = [NSString stringWithFormat:@"push stream fail.module=%@,errid=%d,errmsg=%@",module,errId,errMsg];
        NSLog(@"%@",errinfo);
        [ws showAlert:@"停止推流失败" message:errinfo okTitle:@"确认" cancelTitle:nil ok:nil cancel:nil];
    }];
}

- (void)showAlert:(NSString *)title message:(NSString *)msg okTitle:(NSString *)okTitle cancelTitle:(NSString *)cancelTitle ok:(ActionHandle)succ cancel:(ActionHandle)fail
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    if (okTitle)
    {
        [alert addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:succ]];
    }
    if (cancelTitle)
    {
        [alert addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:fail]];
    }
    [[AppDelegate sharedAppDelegate].navigationViewController presentViewController:alert animated:YES completion:nil];
}

- (void)setChannelId:(UInt64)channelId
{
    _channelId = channelId;
}

- (void)onRecord:(UIButton *)button
{
    button.selected = !button.selected;
    
    __weak typeof(self) ws = self;
    
    if (button.selected)
    {
        __weak typeof(self) ws = self;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"视频录制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [ws startRecord:button type:AV_RECORD_TYPE_VIDEO];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"纯音频录制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [ws startRecord:button type:AV_RECORD_TYPE_AUDIO];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            button.selected = !button.selected;
        }]];
        
        [[AppDelegate sharedAppDelegate].navigationViewController presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [[ILiveRoomManager getInstance] stopRecordVideo:^(id selfPtr) {
            
            [ws showAlert:@"已停止录制" message:nil okTitle:nil cancelTitle:@"确定" ok:nil cancel:nil];
        } failed:^(NSString *module, int errId, NSString *errMsg) {
            
            button.selected = !button.selected;
            
            NSString *errinfo = [NSString stringWithFormat:@"push stream fail.module=%@,errid=%d,errmsg=%@",module,errId,errMsg];
            NSLog(@"%@",errinfo);
            [ws showAlert:@"停止录制失败" message:errinfo okTitle:@"确认" cancelTitle:nil ok:nil cancel:nil];
        }];
    }
}

- (void)showEditAlert:(UIViewController *)rootVC title:(NSString *)title message:(NSString *)msg placeholder:(NSString *)holder okTitle:(NSString *)okTitle cancelTitle:(NSString *)cancelTitle ok:(EditAlertHandle)succ cancel:(ActionHandle)fail
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = holder;
    }];
    
    if (okTitle)
    {
        [alert addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            succ(alert.textFields.firstObject.text);
        }]];
    }
    if (cancelTitle)
    {
        [alert addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:fail]];
    }
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (UIViewController *)viewController
{
    UIResponder *next = self.nextResponder;
    do
    {
        //判断响应者对象是否是视图控制器类型
        if ([next isKindOfClass:[UIViewController class]])
        {
            return (UIViewController *)next;
        }
        next = next.nextResponder;
    }while(next != nil);
    return nil;
}

- (void)startRecord:(UIButton *)button type:(AVRecordType)recordType
{
    __weak typeof(self) ws = self;
    [self showEditAlert:[self viewController] title:@"输入录制文件名" message:nil placeholder:@"录制文件名" okTitle:@"确定" cancelTitle:@"取消" ok:^(NSString * _Nonnull editString) {
        
        NSString *recName = editString && editString.length > 0 ? editString : @"sxb默认录制文件名";
        
        if (ws.delegate && [ws.delegate respondsToSelector:@selector(onRecReport:type:)])
        {
            [ws.delegate onRecReport:recName type:recordType];
        }
        
        ILiveRecordOption *option = [[ILiveRecordOption alloc] init];
        NSString *identifier = [[ILiveLoginManager getInstance] getLoginId];
        option.fileName = [NSString stringWithFormat:@"sxb_%@_%@",identifier,recName];
        NSString *tag = @"8921";
        option.tags = @[tag];
        option.classId = [tag intValue];
        option.isTransCode = NO;
        option.isScreenShot = NO;
        option.isWaterMark = NO;
        option.isScreenShot = NO;
        option.avSdkType = AVSDK_TYPE_NORMAL;
        option.recordType = recordType;
        
        __weak typeof(self) ws = self;
        [[ILiveRoomManager getInstance] startRecordVideo:option succ:^{
            [ws showAlert:@"已开始录制" message:nil okTitle:nil cancelTitle:@"确定" ok:nil cancel:nil];

        } failed:^(NSString *module, int errId, NSString *errMsg) {
            button.selected = !button.selected;
            
            NSString *errinfo = [NSString stringWithFormat:@"push stream fail.module=%@,errid=%d,errmsg=%@",module,errId,errMsg];
            NSLog(@"%@",errinfo);
            [ws showAlert:@"开始录制失败" message:errinfo okTitle:@"确认" cancelTitle:nil ok:nil cancel:nil];
        }];
    } cancel:nil];
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSString *curTime = [dateFormatter stringFromDate:[NSDate date]];
    

}

- (void)onTestSpeed:(UIButton *)button
{
    [self requestTestSpeed];
}

- (void)requestTestSpeed
{
    if (!self.measureSpeeder)
    {
        self.measureSpeeder = [[TIMAVMeasureSpeeder alloc] init];
        self.measureSpeeder.delegate = self;
    }
    
    [self.measureSpeeder requestMeasureSpeedWith:7 authType:6];
}

#pragma mark - measure speed delegate
// 请求测速失败
- (void)onAVMeasureSpeedRequestFailed:(TIMAVMeasureSpeeder *)avts
{
    NSLog(@"----> measure speed fail");
    [self showAlert:@"请求失败" message:nil okTitle:@"确定" cancelTitle:nil ok:nil cancel:nil];
}

// 请求测速成功
- (void)onAVMeasureSpeedRequestSucc:(TIMAVMeasureSpeeder *)avts
{
    NSLog(@"----> measure speed succ");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _alert = [UIAlertController alertControllerWithTitle:@"正在测速" message:@"0/0" preferredStyle:UIAlertControllerStyleAlert];
        
        [_alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.measureSpeeder cancelMeasureSpeed];
        }]];
        
        [[AppDelegate sharedAppDelegate].navigationViewController presentViewController:_alert animated:YES completion:nil];
    });
}

// UDP未成功创建
- (void)onAVMeasureSpeedPingFailed:(TIMAVMeasureSpeeder *)avts
{
}

// 开始拼包
- (void)onAVMeasureSpeedStarted:(TIMAVMeasureSpeeder *)avts
{
}

//测速进度
- (void)onAVMeasureSpeedProgress:(TIMAVMeasureProgressItem *)item
{
    if (_alert)
    {
        _alert.message = [NSString stringWithFormat:@"%d/%d", item.recvPkgNum, item.totalPkgNum];
    }
}

// 发包结束
// isByUser YES, 用户手动取消 NO : 收完所有包或内部超时自动返回
- (void)onAVMeasureSpeedPingCompleted:(TIMAVMeasureSpeeder *)avts byUser:(BOOL)isByUser
{
    [_alert dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"isbyuser = %d", isByUser);
    NSMutableString *text = [NSMutableString string];
    
    NSArray *result = [avts getMeasureResult];
    
    for (TIMAVMeasureSpeederItem *item in result)
    {
        [text appendString:[NSMutableString stringWithFormat:@"%d:",item.interfacePort]];
        
        NSString *ipAddr = [self ip4FromUInt:item.interfaceIP];

        [text appendString:ipAddr];
        
        [text appendString:[NSString stringWithFormat:@":%@,%@", item.idc, item.isp]];
        
        [text appendString:@"\n"];
        
        if (item.sendPkgNum == 0)
        {
            [text appendString:[NSString stringWithFormat:@"未发包"]];
        }
        else
        {
            float lose = (float)(item.sendPkgNum-item.recvPkgNum)/item.sendPkgNum;
            
            [text appendString:[NSString stringWithFormat:@"丢包率:%d%@, ", (int)(lose*100), @"%"]];
        }
        
        [text appendString:[NSString stringWithFormat:@"时延:%lums\n", (unsigned long)item.averageDelay]];
    }
    
    [self showAlert:@"测速结果" message:text okTitle:nil cancelTitle:@"关闭" ok:nil cancel:nil];
}

- (NSString *)ip4FromUInt:(unsigned int)ipNumber
{
    if (sizeof (unsigned int) != 4)
    {
        NSLog(@"Unkown type!");
        return @"";
    }
    
    unsigned int mask = 0xFF000000;
    
    unsigned int array[sizeof(unsigned int)];
    
    int steps = 8;
    int counter;
    
    for (counter = 0; counter < 4 ; counter++)
    {
        array[counter] = ((ipNumber & mask) >> (32-steps*(counter+1)));
        mask >>= steps;
    }
    
    NSMutableString *mutableString = [NSMutableString string];
    
    for (int index = counter-1; index >=0; index--)
    {
        [mutableString appendString:[NSString stringWithFormat:@"%d",array[index]]];
        if (index != 0)
        {
            [mutableString appendString:@"."];
        }
    }
    
    return mutableString;
}
@end
