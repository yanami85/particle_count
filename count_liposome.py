import cv2
import numpy as np
import os
import pandas as pd
import glob
import shutil

def count_particle(file_name):
    img_raw = cv2.imread(os.path.join(f"{file_name}"), 1)
    img = cv2.cvtColor(img_raw, cv2.COLOR_BGR2GRAY)

    h, w = img.shape

    #画像の前処理(拡大)

    mag = 2
    img = cv2.resize(img, (w*mag, h*mag))

    #画像の前処理(ぼかし)
    img_blur = cv2.GaussianBlur(img,(5, 5), 0)

    #2値画像を取得
    _, th = cv2.threshold(img_blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    #モルフォロジー変換(膨張)
    kernel = np.ones((3, 3), np.uint8)
    th = cv2.dilate(th, kernel, iterations = 1)

    #境界検出と描画
    cnt, _ = cv2.findContours(th.astype(np.uint8), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    img_raw = cv2.resize(img_raw, (w*mag, h*mag))
    img_cnt = cv2.drawContours(img_raw, cnt, -1, (0, 255, 255), 1)

    #面積、円形度、中心(x, y座標)、半径を求める。
    # 630 px = 100 nm
    px_nm = 100/630
    Areas = []
    Circularities = []
    Eq_diameters = []
    Center_x = []
    Center_y = []
    Radius = []

    for i in cnt:
        #面積(px*px)
        area = cv2.contourArea(i)
        Areas.append(area)

        #円形度
        arc = cv2.arcLength(i, True)
        circularity = 4*np.pi*area/(arc*arc)
        Circularities.append(circularity)

        #等価直径(px)
        eq_diameter = np.sqrt(4*area/np.pi)*px_nm
        Eq_diameters.append(eq_diameter)

        (center_x, center_y), radius = cv2.minEnclosingCircle(i)
        Center_x.append(center_x)
        Center_y.append(center_y)
        Radius.append(radius)

    df = pd.DataFrame(
        {
            "Circularities": Circularities,
            "Center_x": Center_x,
            "Center_y": Center_y,
            "Radius": Radius
            }
    )

    df["Radius_μm"] = df["Radius"]*100/630
    df_circle = df[df["Circularities"] >= 0.8]


    for data in df_circle.itertuples():
        img = cv2.circle(
            img,
            (int(data.Center_x), int(data.Center_y)),
            int(data.Radius),
            (255, 255, 255),
            3
            )


    df_circle.to_csv(f"{file_name}.csv", index=False)

files = glob.glob(r'img_data\*.tif')

for i in files:
    count_particle(i)


def move_glob(dst_path, pathname, recursive=True):
    for p in glob.glob(pathname, recursive=recursive):
        shutil.move(p, dst_path)
        
move_glob(r'BG(+)', r'img_data\*_BG.tif.csv')
move_glob(r'BG(-)', r'img_data\*.tif.csv')