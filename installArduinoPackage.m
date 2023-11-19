
libpath = fullfile(arduino.supportpkg.getIDERoot, 'portable', 'sketchbook', 'libraries')

libpathlisting = struct2table(dir(libpath))

if(isempty(find(string(libpathlisting(libpathlisting.isdir == true, :).name) == 'ADXL357', 1)))
    repo = gitclone("https://github.com/Chimera-PRIUS-Avionics/ADXL357");

    movefile(repo.WorkingFolder, libpath)
end
