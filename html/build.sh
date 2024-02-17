docs="../docs"
if [ -d "${docs}" ]; then
    echo "Building to ${docs}"
    rm -r ${docs}/*
    parcel build index.html --dist-dir ${docs}
else
    echo "Error: \"${docs}\" directory NOT found"
    exit 1
fi
if [ -d "dist/" ]; then
    echo "Cleaing up dist, because parcel isn't gonna"
    rm -r dist/*
fi
