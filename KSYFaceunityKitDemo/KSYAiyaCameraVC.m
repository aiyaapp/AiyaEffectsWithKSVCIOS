#import "KSYAiyaCameraVC.h"
#import "KSYAiyaGPUImageTrackFilter.h"
#import "KSYAiyaGPUImageEffectFilter.h"
#import <AiyaCameraSDK/AiyaCameraSDK.h>

@interface KSYAiyaCameraVC ()
{
    UISwipeGestureRecognizer *_swipeGest;
    NSDateFormatter * _dateFormatter;
    int64_t _seconds;
    NSMutableDictionary *_obsDict;
    AiyaCameraEffect *_cameraEffect;
    KSYAiyaGPUImageTrackFilter *_aiyaTrackFilter;
    KSYAiyaGPUImageEffectFilter *_aiyaEffectFilter;
}
@end

@implementation KSYAiyaCameraVC

- (id) initWithCfg:(KSYPresetCfgView*)presetCfgView{
    self = [super init];
    _presetCfgView = presetCfgView;
    [self initObservers];
    self.view.backgroundColor = [UIColor whiteColor];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [AiyaLicenseManager initLicense:@"5d86566163274e34aa40a4574749ccb5"];
    
    _kit = [[KSYGPUStreamerKit alloc] initWithDefaultCfg];
    [self addSubViews];
    [self addSwipeGesture];
    // 采集相关设置初始化
    [self setCaptureCfg];
    //推流相关设置初始化
    [self setStreamerCfg];
    //设置贴纸相关
    [self setupAiyaCamera];
    // 打印版本号信息
    NSLog(@"version: %@", [_kit getKSYVersion]);
    
    if (_kit) { // init with default filter
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit startPreview:self.view];
    }
}
- (void)addSubViews{
    _ctrlView  = [[KSYCtrlView alloc] init];
    _ctrlView.lblNetwork.text = @"点击Open";
    [self.view addSubview:_ctrlView];
    _ctrlView.frame = self.view.frame;
    
    // connect UI
    __weak KSYAiyaCameraVC *weakself = self;
    _ctrlView.onBtnBlock = ^(id btn){
        [weakself onBasicCtrl:btn];
    };
}
- (void) addSwipeGesture{
    SEL onSwip =@selector(swipeController:);
    _swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                          action:onSwip];
    _swipeGest.direction |= UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:_swipeGest];
}
- (void)swipeController:(UISwipeGestureRecognizer *)swipGestRec{
    if (swipGestRec == _swipeGest){
        CGRect rect = self.view.frame;
        if ( CGRectEqualToRect(rect, _ctrlView.frame)){
            rect.origin.x = rect.size.width; // hide
        }
        [UIView animateWithDuration:0.1 animations:^{
            _ctrlView.frame = rect;
        }];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [self layoutUI];
    [UIApplication sharedApplication].idleTimerDisabled=YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled=NO;
}
- (void) layoutUI {
    if(_ctrlView){
        _ctrlView.frame = self.view.frame;
        [_ctrlView layoutUI];
    }
}


#pragma mark -  state change
- (void) onCaptureStateChange:(NSNotification *)notification{
    NSLog(@"new capStat: %@", _kit.getCurCaptureStateName );
    self.ctrlView.lblStat.text = [_kit getCurCaptureStateName];
}

- (void) onNetStateEvent     :(NSNotification *)notification{
    switch (_kit.streamerBase.netStateCode) {
        case KSYNetStateCode_SEND_PACKET_SLOW: {
            _ctrlView.lblStat.notGoodCnt++;
            break;
        }
        case KSYNetStateCode_EST_BW_RAISE: {
            _ctrlView.lblStat.bwRaiseCnt++;
            break;
        }
        case KSYNetStateCode_EST_BW_DROP: {
            _ctrlView.lblStat.bwDropCnt++;
            break;
        }
        default:break;
    }
}
- (void) onStreamStateChange :(NSNotification *)notification{
    if (_kit.streamerBase){
        NSLog(@"stream State %@", [_kit.streamerBase getCurStreamStateName]);
    }
    _ctrlView.lblStat.text = [_kit.streamerBase getCurStreamStateName];
    if(_kit.streamerBase.streamState == KSYStreamStateError) {
        [self onStreamError:_kit.streamerBase.streamErrorCode];
    }
    else if (_kit.streamerBase.streamState == KSYStreamStateConnecting) {
        [_ctrlView.lblStat initStreamStat]; // 尝试开始连接时,重置统计数据
    }
}

- (void) onStreamError:(KSYStreamErrorCode) errCode{
    _ctrlView.lblStat.text  = [_kit.streamerBase getCurKSYStreamErrorCodeName];
    if (errCode == KSYStreamErrorCode_CONNECT_BREAK) {
        // Reconnect
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            _kit.streamerBase.bWithVideo = YES;
            [_kit.streamerBase startStream:self.hostURL];
        });
    }
    else if (errCode == KSYStreamErrorCode_AV_SYNC_ERROR) {
        NSLog(@"audio video is not synced, please check timestamp");
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            NSLog(@"try again");
            _kit.streamerBase.bWithVideo = YES;
            [_kit.streamerBase startStream:self.hostURL];
        });
    }
}
#pragma mark - timer respond per second
- (void)onTimer:(NSTimer *)theTimer{
    if (_kit.streamerBase.streamState == KSYStreamStateConnected ) {
        [_ctrlView.lblStat updateState: _kit.streamerBase];
    }
}
#pragma mark - UI respond
//ctrView control (for basic ctrl)
- (void) onBasicCtrl: (id) btn {
    if (btn == _ctrlView.btnFlash){
        [self onFlash];
    }
    else if (btn == _ctrlView.btnCameraToggle){
        [self onCameraToggle];
    }
    else if (btn == _ctrlView.btnQuit){
        [self onQuit];
    }
    else if(btn == _ctrlView.btnCapture){
        [self onCapture];
    }
    else if(btn == _ctrlView.btnStream){
        [self onStream];
    }
}
#pragma mark - subviews: basic ctrl
- (void) onFlash {
    [_kit toggleTorch];
}
- (void) onCameraToggle{ // see kit or block
    [_kit switchCamera];
    if (_kit.vCapDev && _kit.vCapDev.cameraPosition == AVCaptureDevicePositionBack) {
        [_ctrlView.btnFlash setEnabled:YES];
    }
    else{
        [_ctrlView.btnFlash setEnabled:NO];
    }
}
- (void) onCapture{
    if (!_kit.vCapDev.isRunning){
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit startPreview:self.view];
    }
    else {
        [_kit stopPreview];
    }
}
- (void) onStream{
    if (_kit.streamerBase.streamState == KSYStreamStateIdle ||
        _kit.streamerBase.streamState == KSYStreamStateError) {
        [_kit.streamerBase startStream:self.hostURL];
    }
    else {
        [_kit.streamerBase stopStream];
    }
}
- (void) onQuit{
    [_kit stopPreview];
    _kit = nil;
    [self rmObservers];
    [self dismissViewControllerAnimated:FALSE completion:nil];
}

#define SEL_VALUE(SEL_NAME) [NSValue valueWithPointer:@selector(SEL_NAME)]

- (void) initObservers{
    _obsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                SEL_VALUE(onCaptureStateChange:) ,  KSYCaptureStateDidChangeNotification,
                SEL_VALUE(onStreamStateChange:) ,   KSYStreamStateDidChangeNotification,
                SEL_VALUE(onNetStateEvent:) ,       KSYNetStateEventNotification,
                nil];
}
- (void) addObservers {
    [super addObservers];
    //KSYStreamer state changes
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    for (NSString* key in _obsDict) {
        SEL aSel = [[_obsDict objectForKey:key] pointerValue];
        [dc addObserver:self
               selector:aSel
                   name:key
                 object:nil];
    }
}

- (void) rmObservers {
    [super rmObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadDataWithItem:(NSString *)fileName{
    //创建url
    NSString *urlStr = [NSString stringWithFormat:@"http://ks3-cn-beijing.ksyun.com/ksy.vcloud.sdk/Ios/%@",fileName];
    //urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlStr];
    //创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //__weak typeof(self) weakSelf = self;
    //创建会话 这里使用一个全局会话 并启动任务
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            //注意location是下载后的临时保存路径，需要将他移动到需要保存的位置
            NSError *saveError;
            NSString *cachePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            NSString *savePath=[cachePath stringByAppendingPathComponent:fileName];
            NSURL *saveUrl = [NSURL fileURLWithPath:savePath];
            [[NSFileManager defaultManager] copyItemAtURL:location toURL:saveUrl error:&saveError];
            if (!saveError) {
                NSLog(@"save sucess.");
            }else{
                NSLog(@"saveError is :%@",saveError.localizedDescription);
            }
        }else{
            NSLog(@"error is %@", error.localizedDescription);
        }
    }];
    [downloadTask resume];
}

- (NSString *)dataFilePathWithName:(NSString *)name{
    NSString *cachePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *savePath=[cachePath stringByAppendingPathComponent:name];
    return savePath;
}

#pragma mark - Capture & stream setup
- (void) setCaptureCfg {
    _kit.capPreset        = [self.presetCfgView capResolution];
    _kit.previewDimension = [self.presetCfgView capResolutionSize];
    _kit.streamDimension  = [self.presetCfgView strResolutionSize ];
    _kit.videoFPS       = [self.presetCfgView frameRate];
    _kit.cameraPosition = [self.presetCfgView cameraPos];
    _kit.videoProcessingCallback = ^(CMSampleBufferRef buf){
    };
}

-(void)setupAiyaCamera{
    
    _cameraEffect = [[AiyaCameraEffect alloc]init];
    _aiyaTrackFilter = [[KSYAiyaGPUImageTrackFilter alloc]initWithAiyaCameraEffect:_cameraEffect];
    _aiyaEffectFilter = [[KSYAiyaGPUImageEffectFilter alloc]initWithAiyaCameraEffect:_cameraEffect];
    [_aiyaEffectFilter setEffectPath:[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"gougou"]];
    GPUImageOutput<GPUImageInput>* beautifilter = [[KSYGPUBeautifyPlusFilter alloc]init];
    
    // 用滤镜组 将 滤镜 串联成整体
    [beautifilter addTarget:_aiyaEffectFilter];
    GPUImageFilterGroup * fg = [[GPUImageFilterGroup alloc] init];
    [fg addFilter:_aiyaTrackFilter];
    [fg addFilter:_aiyaEffectFilter];
    [fg addFilter:beautifilter];
    [fg setInitialFilters:[NSArray arrayWithObjects:_aiyaTrackFilter,beautifilter,nil]];
    [fg setTerminalFilter:_aiyaEffectFilter];

    [_kit setupFilter:fg];
}

- (void) setStreamerCfg { // must set after capture
    if (_kit.streamerBase == nil) {
        return;
    }
    if (_presetCfgView){ // cfg from presetcfgview
        _kit.streamerBase.videoCodec       = [_presetCfgView videoCodec];
        _kit.streamerBase.videoInitBitrate = [_presetCfgView videoKbps]*6/10;//60%
        _kit.streamerBase.videoMaxBitrate  = [_presetCfgView videoKbps];
        _kit.streamerBase.videoMinBitrate  = 0; //
        _kit.streamerBase.audioCodec       = [_presetCfgView audioCodec];
        _kit.streamerBase.audiokBPS        = [_presetCfgView audioKbps];
        _kit.streamerBase.videoFPS         = [_presetCfgView frameRate];
        _kit.streamerBase.bwEstimateMode   = [_presetCfgView bwEstMode];
        _kit.streamerBase.logBlock = ^(NSString* str){ };
        _hostURL = [NSURL URLWithString:[_presetCfgView hostUrl]];
    }
    [self defaultStramCfg];
}

- (void) defaultStramCfg{
        _kit.streamerBase.videoCodec = KSYVideoCodec_AUTO;
        _kit.streamerBase.videoInitBitrate =  800;
        _kit.streamerBase.videoMaxBitrate  = 1000;
        _kit.streamerBase.videoMinBitrate  =    0;
        _kit.streamerBase.audiokBPS        =   48;
        _kit.streamerBase.videoFPS = 15;
        _kit.streamerBase.logBlock = ^(NSString* str){
        };
    _hostURL = [NSURL URLWithString:@"rtmp://test.uplive.ksyun.com/live/823"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc{
    [_cameraEffect deinitEffectContext];
}
@end
