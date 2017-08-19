import java.awt { Color }
import java.awt.event { ActionEvent }
import javax.swing { JFrame, JMenu, JMenuBar, JMenuItem, JPanel, UIManager }

class Main {
    shared static Integer scale = 4;
    shared static void render(Machine machine, JPanel panel) {
        value g = panel.graphics;

        g.color = Color.\iBLACK;
        g.fillRect(0, 0, panel.width, panel.height);

        g.color = Color.\iGREEN;
        for (x in 0:machine.width) {
            for (y in 0:machine.height) {
                if (machine.getPixel(x, y)) {
                    g.fillRect(x * scale, y * scale, scale, scale);
                }
            }
        }
    }
    new create() {} // TODO: no better way to do this?
}

class ActualPeripherals() satisfies Peripherals {
    shared actual void beep() {
        print("beep!");
    }
    shared actual Integer waitForKeyPressed() => 0;
}

shared void main() {
    value machine = Machine(ActualPeripherals());

    // TODO: configurable key maps
    // TODO: per-rom key maps
    value loadMenuItem = JMenuItem("Load ROM...");
    value renderMenuItem = JMenuItem("Render Now");
    value fileMenu = JMenu("File");
    fileMenu.add(loadMenuItem);
    value displayMenu = JMenu("Display");
    displayMenu.add(renderMenuItem);
    value menuBar = JMenuBar();
    menuBar.add(fileMenu);
    menuBar.add(displayMenu);
    value panel = JPanel();
    panel.setSize(
        machine.width * Main.scale,
        machine.height * Main.scale);
    value frame = JFrame("CHIP-8");
    frame.jMenuBar = menuBar;
    frame.contentPane.add(panel);
    frame.defaultCloseOperation = JFrame.exitOnClose;
    // TODO: make frame stick to panel size
    // TODO: configurable pixel scaling (with hotkeys like Ctrl+, Ctrl-)
    //frame.resizable = false;
    //frame.pack();
    frame.setSize(64 * 4 + 100, 32 * 4 + 100);
    UIManager.setLookAndFeel(UIManager.systemLookAndFeelClassName);
    frame.setVisible(true);

    renderMenuItem.addActionListener((ActionEvent e) {
        Main.render(machine, panel);
    });
    Main.render(machine, panel);
}